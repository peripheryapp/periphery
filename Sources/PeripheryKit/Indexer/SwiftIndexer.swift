import Foundation
import SwiftSyntax
import SwiftIndexStore
import SystemPackage
import Shared

public final class SwiftIndexer: Indexer {
    private let sourceFiles: [FilePath: Set<String>]
    private let graph: SourceGraph
    private let logger: ContextualLogger
    private let configuration: Configuration
    private let indexStorePaths: [FilePath]

    private lazy var letShorthandWorkaroundEnabled: Bool = {
        SwiftVersion.current.version.isVersion(lessThan: "5.8")
    }()

    public required init(
        sourceFiles: [FilePath: Set<String>],
        graph: SourceGraph,
        indexStorePaths: [FilePath],
        logger: Logger = .init(),
        configuration: Configuration = .shared
    ) {
        self.sourceFiles = sourceFiles
        self.graph = graph
        self.indexStorePaths = indexStorePaths
        self.logger = logger.contextualized(with: "index:swift")
        self.configuration = configuration
        super.init(configuration: configuration)
    }

    public func perform() throws {
        var unitsByFile: [FilePath: [(IndexStore, IndexStoreUnit)]] = [:]
        let allSourceFiles = Set(sourceFiles.keys)
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: allSourceFiles)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        for indexStorePath in indexStorePaths {
            logger.debug("Reading \(indexStorePath)")
            let indexStore = try IndexStore.open(store: URL(fileURLWithPath: indexStorePath.string), lib: .open())

            try indexStore.forEachUnits(includeSystem: false) { unit -> Bool in
                guard let filePath = try indexStore.mainFilePath(for: unit) else { return true }

                let file = FilePath(filePath)

                if includedFiles.contains(file) {
                    unitsByFile[file, default: []].append((indexStore, unit))
                }

                return true
            }
        }

        let indexedFiles = Set(unitsByFile.keys)
        let unindexedFiles = allSourceFiles.subtracting(excludedFiles).subtracting(indexedFiles)

        if !unindexedFiles.isEmpty {
            unindexedFiles.forEach { logger.debug("Source file not indexed: \($0)") }
            let targets: Set<String> = Set(unindexedFiles.flatMap { sourceFiles[$0] ?? [] })
            throw PeripheryError.unindexedTargetsError(targets: targets, indexStorePaths: indexStorePaths)
        }

        let jobs = try unitsByFile.map { (file, units) -> Job in
            let modules = try units.reduce(into: Set<String>()) { (set, tuple) in
                let (indexStore, unit) = tuple
                if let name = try indexStore.moduleName(for: unit) {
                    let (didInsert, _) = set.insert(name)
                    if !didInsert {
                        let targets = try Set(units.compactMap { try indexStore.target(for: $0.1) })
                        throw PeripheryError.conflictingIndexUnitsError(file: file, module: name, unitTargets: targets)
                    }
                }
            }
            let sourceFile = SourceFile(path: file, modules: modules)

            return Job(
                file: sourceFile,
                units: units,
                graph: graph,
                logger: logger,
                configuration: configuration,
                letShorthandWorkaroundEnabled: letShorthandWorkaroundEnabled
            )
        }

        let phaseOneLogger = logger.contextualized(with: "phase:one")
        let phaseOneInterval = logger.beginInterval("index:swift:phase:one")

        try JobPool(jobs: jobs).forEach { job in
            let elapsed = try Benchmark.measure {
                try job.phaseOne()
            }

            phaseOneLogger.debug("\(job.file.path) (\(elapsed)s)")
        }

        logger.endInterval(phaseOneInterval)

        let phaseTwoLogger = logger.contextualized(with: "phase:two")
        let phaseTwoInterval = logger.beginInterval("index:swift:phase:two")

        try JobPool(jobs: jobs).forEach { job in
            let elapsed = try Benchmark.measure {
                try job.phaseTwo()
            }

            phaseTwoLogger.debug("\(job.file.path) (\(elapsed)s)")
        }

        logger.endInterval(phaseTwoInterval)
    }

    // MARK: - Private

    private class Job {
        let file: SourceFile

        private let units: [(IndexStore, IndexStoreUnit)]
        private let graph: SourceGraph
        private let logger: ContextualLogger
        private let configuration: Configuration
        private let letShorthandWorkaroundEnabled: Bool

        required init(
            file: SourceFile,
            units: [(IndexStore, IndexStoreUnit)],
            graph: SourceGraph,
            logger: ContextualLogger,
            configuration: Configuration,
            letShorthandWorkaroundEnabled: Bool

        ) {
            self.file = file
            self.units = units
            self.graph = graph
            self.logger = logger
            self.configuration = configuration
            self.letShorthandWorkaroundEnabled = letShorthandWorkaroundEnabled
        }

        struct RawRelation {
            struct Symbol {
                let name: String?
                let usr: String?
                let kind: IndexStoreSymbol.Kind
                let subKind: IndexStoreSymbol.SubKind
            }

            let symbol: Symbol
            let roles: IndexStoreOccurrence.Role
        }

        struct RawDeclaration {
            struct Key: Hashable {
                let kind: Declaration.Kind
                let name: String?
                let isImplicit: Bool
                let isObjcAccessible: Bool
                let location: SourceLocation
            }

            let usr: String
            let kind: Declaration.Kind
            let name: String?
            let isImplicit: Bool
            let isObjcAccessible: Bool
            let location: SourceLocation

            var key: Key {
                Key(kind: kind, name: name, isImplicit: isImplicit, isObjcAccessible: isObjcAccessible, location: location)
            }
        }

        /// Phase one reads the index store and establishes the declaration hierarchy and the majority of references.
        /// Some references may depend upon declarations in other files, and thus their association is deferred until
        /// phase two.
        func phaseOne() throws {
            var rawDeclsByKey: [RawDeclaration.Key: [(RawDeclaration, [RawRelation])]] = [:]

            for (indexStore, unit) in units {
                try indexStore.forEachRecordDependencies(for: unit) { dependency in
                    guard case let .record(record) = dependency else { return true }

                    try indexStore.forEachOccurrences(for: record) { occurrence in
                        guard occurrence.symbol.language == .swift,
                              let usr = occurrence.symbol.usr,
                              let location = transformLocation(occurrence.location)
                              else { return true }

                        if !occurrence.roles.intersection([.definition, .declaration]).isEmpty {
                            if let (decl, relations) = try parseRawDeclaration(occurrence, usr, location, indexStore) {
                                rawDeclsByKey[decl.key, default: []].append((decl, relations))
                            }
                        }

                        if !occurrence.roles.intersection([.reference]).isEmpty {
                            try parseReference(occurrence, usr, location, indexStore)
                        }

                        if !occurrence.roles.intersection([.implicit]).isEmpty {
                            try parseImplicit(occurrence, usr, location, indexStore)
                        }

                        return true
                    }

                    return true
                }
            }

            for (key, values) in rawDeclsByKey {
                let usrs = Set(values.map { $0.0.usr })
                let decl = Declaration(kind: key.kind, usrs: usrs, location: key.location)

                decl.name = key.name
                decl.isImplicit = key.isImplicit
                decl.isObjcAccessible = key.isObjcAccessible

                if decl.isImplicit {
                    graph.markRetained(decl)
                }

                if decl.isObjcAccessible && configuration.retainObjcAccessible {
                    graph.markRetained(decl)
                }

                let relations = values.flatMap { $0.1 }
                try parseDeclaration(decl, relations)

                graph.add(decl)
                declarations.append(decl)
            }

            establishDeclarationHierarchy()
        }

        /// Phase two associates latent references, and performs other actions that depend on the completed source graph.
        func phaseTwo() throws {
            let multiplexingSyntaxVisitor = try MultiplexingSyntaxVisitor(file: file)
            let declarationSyntaxVisitor = multiplexingSyntaxVisitor.add(DeclarationSyntaxVisitor.self)
            declarationSyntaxVisitor.letShorthandWorkaroundEnabled = letShorthandWorkaroundEnabled
            let importSyntaxVisitor = multiplexingSyntaxVisitor.add(ImportSyntaxVisitor.self)

            multiplexingSyntaxVisitor.visit()

            file.importStatements = importSyntaxVisitor.importStatements

            associateLatentReferences()
            associateDanglingReferences()
            visitDeclarations(using: declarationSyntaxVisitor)
            identifyUnusedParameters(using: multiplexingSyntaxVisitor)
            applyCommentCommands(using: multiplexingSyntaxVisitor)
        }

        private var declarations: [Declaration] = []
        private var childDeclsByParentUsr: [String: Set<Declaration>] = [:]
        private var referencesByUsr: [String: Set<Reference>] = [:]
        private var danglingReferences: [Reference] = []
        private var varParameterUsrs: Set<String> = []

        private func establishDeclarationHierarchy() {
            graph.withLock {
                for (parent, decls) in childDeclsByParentUsr {
                    guard let parentDecl = graph.explicitDeclaration(withUsr: parent) else {
                        if varParameterUsrs.contains(parent) {
                            // These declarations are children of a parameter and are redundant.
                            decls.forEach { graph.removeUnsafe($0) }
                        }

                        continue
                    }

                    for decl in decls {
                        decl.parent = parentDecl
                    }

                    parentDecl.declarations.formUnion(decls)
                }
            }
        }

        private func associateLatentReferences() {
            for (usr, refs) in referencesByUsr {
                graph.withLock {
                    if let decl = graph.explicitDeclaration(withUsr: usr) {
                        for ref in refs {
                            associateUnsafe(ref, with: decl)
                        }
                    } else {
                        danglingReferences.append(contentsOf: refs)
                    }
                }
            }
        }

        // Swift does not associate some type references with the containing declaration, resulting in references
        // with no clear parent. Property references are one example: https://bugs.swift.org/browse/SR-13766.
        private func associateDanglingReferences() {
            guard !danglingReferences.isEmpty else { return }

            let explicitDeclarations = declarations.filter { !$0.isImplicit }
            let declsByLocation = explicitDeclarations
                .reduce(into: [SourceLocation: [Declaration]]()) { (result, decl) in
                    result[decl.location, default: []].append(decl)
                }
            let declsByLine = explicitDeclarations
                .reduce(into: [Int64: [Declaration]]()) { (result, decl) in
                    result[decl.location.line, default: []].append(decl)
                }

            for ref in danglingReferences {
                guard let candidateDecls =
                        declsByLocation[ref.location] ??
                        declsByLine[ref.location.line] else { continue }

                // The vast majority of the time there will only be a single declaration for this location,
                // however it is possible for there to be more than one. In that case, first attempt to associate with
                // a decl without a parent, as the reference may be a related type of a class/struct/etc.
                if let decl = candidateDecls.first(where: { $0.parent == nil }) {
                    associate(ref, with: decl)
                } else if let decl = candidateDecls.sorted().first {
                    // Fallback to using the first declaration.
                    // Sorting the declarations helps in the situation where the candidate declarations includes a
                    // property/subscript, and a getter on the same line. The property/subscript is more likely to be
                    // the declaration that should hold the references.
                    associate(ref, with: decl)
                }
            }
        }

        private func applyCommentCommands(using syntaxVisitor: MultiplexingSyntaxVisitor) {
            let fileCommands = CommentCommand.parseCommands(in: syntaxVisitor.syntax.leadingTrivia)

            if fileCommands.contains(.ignoreAll) {
                retainHierarchy(declarations)
            } else {
                for decl in declarations {
                    if decl.commentCommands.contains(.ignore) {
                        retainHierarchy([decl])
                    }
                }
            }
        }

        private func visitDeclarations(using declarationVisitor: DeclarationSyntaxVisitor) {
            let declarationsByLocation = declarationVisitor.resultsByLocation

            for decl in declarations {
                guard let result = declarationsByLocation[decl.location] else { continue }

                applyDeclarationMetadata(to: decl, with: result)
                markLetShorthandContainerIfNeeded(declaration: decl)
            }
        }

        private func markLetShorthandContainerIfNeeded(declaration: Declaration) {
            guard !declaration.letShorthandIdentifiers.isEmpty else { return }
            graph.markLetShorthandContainer(declaration)
        }

        private func applyDeclarationMetadata(to decl: Declaration, with result: DeclarationSyntaxVisitor.Result) {
            graph.withLock {
                if let accessibility = result.accessibility {
                    decl.accessibility = .init(value: accessibility, isExplicit: true)
                }

                decl.attributes = Set(result.attributes)
                decl.modifiers = Set(result.modifiers)
                decl.commentCommands = Set(result.commentCommands)
                decl.declaredType = result.variableType
                decl.letShorthandIdentifiers = result.letShorthandIdentifiers
                decl.hasCapitalSelfFunctionCall = result.hasCapitalSelfFunctionCall

                for ref in decl.references.union(decl.related) {
                    if result.inheritedTypeLocations.contains(ref.location) {
                        if decl.kind == .class, ref.kind == .class {
                            ref.role = .inheritedClassType
                        } else if decl.kind == .protocol, ref.kind == .protocol {
                            ref.role = .refinedProtocolType
                        }
                    } else if result.variableTypeLocations.contains(ref.location) {
                        ref.role = .varType
                    } else if result.returnTypeLocations.contains(ref.location) {
                        ref.role = .returnType
                    } else if result.parameterTypeLocations.contains(ref.location) {
                        ref.role = .parameterType
                    } else if result.genericParameterLocations.contains(ref.location) {
                        ref.role = .genericParameterType
                    } else if result.genericConformanceRequirementLocations.contains(ref.location) {
                        ref.role = .genericRequirementType
                    }
                }
            }
        }

        private func retainHierarchy(_ decls: [Declaration]) {
            decls.forEach {
                graph.markRetained($0)
                $0.unusedParameters.forEach { graph.markRetained($0) }
                retainHierarchy(Array($0.declarations))
            }
        }

        private func associate(_ ref: Reference, with decl: Declaration) {
            graph.withLock {
                associateUnsafe(ref, with: decl)
            }
        }

        private func associateUnsafe(_ ref: Reference, with decl: Declaration) {
            ref.parent = decl

            if ref.isRelated {
                decl.related.insert(ref)
            } else {
                decl.references.insert(ref)
            }
        }

        private func identifyUnusedParameters(using syntaxVisitor: MultiplexingSyntaxVisitor) {
            let functionDecls = declarations.filter { $0.kind.isFunctionKind }
            let functionDeclsByLocation = functionDecls.filter { $0.kind.isFunctionKind }.map { ($0.location, $0) }.reduce(into: [SourceLocation: Declaration]()) { $0[$1.0] = $1.1 }

            let analyzer = UnusedParameterAnalyzer()
            let paramsByFunction = analyzer.analyze(
                file: file,
                syntax: syntaxVisitor.syntax,
                locationConverter: syntaxVisitor.locationConverter,
                parseProtocols: true)

            for (function, params) in paramsByFunction {
                guard let functionDecl = functionDeclsByLocation[function.location] else {
                    // The declaration may not exist if the code was not compiled due to build conditions, e.g #if.
                    logger.debug("Failed to associate indexed function for parameter function '\(function.name)' at \(function.location).")
                    continue
                }

                let ignoredParamNames = functionDecl.commentCommands.flatMap { command -> [String] in
                    switch command {
                    case let .ignoreParameters(params):
                        return params
                    default:
                        return []
                    }
                }

                graph.withLock {
                    for param in params {
                        let paramDecl = param.declaration
                        paramDecl.parent = functionDecl
                        functionDecl.unusedParameters.insert(paramDecl)
                        graph.addUnsafe(paramDecl)

                        if (functionDecl.isObjcAccessible && configuration.retainObjcAccessible) || ignoredParamNames.contains(param.name) {
                            graph.markRetainedUnsafe(paramDecl)
                        }
                    }
                }
            }
        }

        private func parseRawDeclaration(
            _ occurrence: IndexStoreOccurrence,
            _ usr: String,
            _ location: SourceLocation,
            _ indexStore: IndexStore
        ) throws -> (RawDeclaration, [RawRelation])? {
            guard let kind = transformDeclarationKind(occurrence.symbol.kind, occurrence.symbol.subKind)
            else { return nil }

            guard kind != .varParameter else {
                // Ignore indexed parameters as unused parameter identification is performed separately using SwiftSyntax.
                // Record the USR so that we can also ignore implicit accessor declarations.
                varParameterUsrs.insert(usr)
                return nil
            }

            let decl = RawDeclaration(
                usr: usr,
                kind: kind,
                name: occurrence.symbol.name,
                isImplicit: occurrence.roles.contains(.implicit),
                isObjcAccessible: usr.hasPrefix("c:"),
                location: location)

            var relations: [RawRelation] = []

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                relations.append(
                    .init(
                        symbol: .init(
                            name: rel.symbol.name,
                            usr: rel.symbol.usr,
                            kind: rel.symbol.kind,
                            subKind: rel.symbol.subKind
                        ),
                        roles: rel.roles
                    )
                )

                return true
            }

            return (decl, relations)
        }

        private func parseDeclaration(
            _ decl: Declaration,
            _ relations: [RawRelation]
        ) throws {
            for rel in relations {
                if !rel.roles.intersection([.childOf]).isEmpty {
                    if let parentUsr = rel.symbol.usr {
                        self.childDeclsByParentUsr[parentUsr, default: []].insert(decl)
                    }
                }

                if !rel.roles.intersection([.overrideOf]).isEmpty {
                    let baseFunc = rel.symbol

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = transformReferenceKind(baseFunc.kind, baseFunc.subKind) {
                        let reference = Reference(kind: baseFuncKind, usr: baseFuncUsr, location: decl.location)
                        reference.name = baseFunc.name
                        reference.isRelated = true

                        graph.withLock {
                            graph.addUnsafe(reference)
                            associateUnsafe(reference, with: decl)
                        }
                    }
                }

                if !rel.roles.intersection([.baseOf, .calledBy, .extendedBy, .containedBy]).isEmpty {
                    let referencer = rel.symbol

                    if let referencerUsr = referencer.usr, let referencerKind = decl.kind.referenceEquivalent {
                        for usr in decl.usrs {
                            let reference = Reference(kind: referencerKind, usr: usr, location: decl.location)
                            reference.name = decl.name

                            if rel.roles.contains(.baseOf) {
                                reference.isRelated = true
                            }

                            graph.add(reference)
                            self.referencesByUsr[referencerUsr, default: []].insert(reference)
                        }
                    }
                }
            }
        }

        private func parseImplicit(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation,
            _ indexStore: IndexStore
        ) throws {
            var refs = [Reference]()

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if !rel.roles.intersection([.overrideOf]).isEmpty {
                    let baseFunc = rel.symbol

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = transformReferenceKind(baseFunc.kind, baseFunc.subKind) {
                        let reference = Reference(kind: baseFuncKind, usr: baseFuncUsr, location: location)
                        reference.name = baseFunc.name
                        reference.isRelated = true

                        self.referencesByUsr[occurrenceUsr, default: []].insert(reference)
                        refs.append(reference)
                    }
                }

                return true
            }

            graph.withLock {
                refs.forEach { graph.addUnsafe($0) }
            }
        }

        private func parseReference(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation,
            _ indexStore: IndexStore
        ) throws {
            guard let kind = transformReferenceKind(occurrence.symbol.kind, occurrence.symbol.subKind)
                  else { return }

            guard kind != .varParameter else {
                // Ignore indexed parameters as unused parameter identification is performed separately using SwiftSyntax.
                return
            }

            var refs = [Reference]()

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if !rel.roles.intersection([.baseOf, .calledBy, .containedBy, .extendedBy]).isEmpty {
                    let referencer = rel.symbol

                    if let referencerUsr = referencer.usr {
                        let ref = Reference(kind: kind, usr: occurrenceUsr, location: location)
                        ref.name = occurrence.symbol.name

                        if rel.roles.contains(.baseOf) {
                            ref.isRelated = true
                        }

                        refs.append(ref)
                        self.referencesByUsr[referencerUsr, default: []].insert(ref)
                    }
                }

                return true
            }

            if refs.isEmpty {
                let ref = Reference(kind: kind, usr: occurrenceUsr, location: location)
                ref.name = occurrence.symbol.name
                refs.append(ref)

                // The index store doesn't contain any relations for this reference, save it so that we can attempt
                // to associate it with the correct declaration later based on location.
                if ref.kind != .module {
                    danglingReferences.append(ref)
                }
            }

            graph.withLock {
                refs.forEach { graph.addUnsafe($0) }
            }
        }

        private func transformLocation(_ input: IndexStoreOccurrence.Location) -> SourceLocation? {
            return SourceLocation(file: file, line: input.line, column: input.column)
        }

        private func transformDeclarationKind(_ kind: IndexStoreSymbol.Kind, _ subKind: IndexStoreSymbol.SubKind) -> Declaration.Kind? {
            switch subKind {
            case .accessorGetter: return .functionAccessorGetter
            case .accessorSetter: return .functionAccessorSetter
            case .swiftAccessorDidSet: return .functionAccessorDidset
            case .swiftAccessorWillSet: return .functionAccessorWillset
            case .swiftAccessorMutableAddressor: return .functionAccessorMutableaddress
            case .swiftAccessorAddressor: return .functionAccessorAddress
            case .swiftSubscript: return .functionSubscript
            case .swiftInfixOperator: return .functionOperatorInfix
            case .swiftPrefixOperator: return .functionOperatorPrefix
            case .swiftPostfixOperator: return .functionOperatorPostfix
            case .swiftGenericTypeParam: return .genericTypeParam
            case .swiftAssociatedtype: return .associatedtype
            case .swiftExtensionOfClass: return .extensionClass
            case .swiftExtensionOfStruct: return .extensionStruct
            case .swiftExtensionOfProtocol: return .extensionProtocol
            case .swiftExtensionOfEnum: return .extensionEnum
            default: break
            }

            switch kind {
            case .module: return .module
            case .enum: return .enum
            case .struct: return .struct
            case .class: return .class
            case .protocol: return .protocol
            case .extension: return .extension
            case .typealias: return .typealias
            case .function: return .functionFree
            case .variable: return .varGlobal
            case .enumConstant: return .enumelement
            case .instanceMethod: return .functionMethodInstance
            case .classMethod: return .functionMethodClass
            case .staticMethod: return .functionMethodStatic
            case .instanceProperty: return .varInstance
            case .classProperty: return .varClass
            case .staticProperty: return .varStatic
            case .constructor: return .functionConstructor
            case .destructor: return .functionDestructor
            case .parameter: return .varParameter
            default: return nil
            }
        }

        private func transformReferenceKind(_ kind: IndexStoreSymbol.Kind, _ subKind: IndexStoreSymbol.SubKind) -> Reference.Kind? {
            switch subKind {
            case .accessorGetter: return .functionAccessorGetter
            case .accessorSetter: return .functionAccessorSetter
            case .swiftAccessorDidSet: return .functionAccessorDidset
            case .swiftAccessorWillSet: return .functionAccessorWillset
            case .swiftAccessorMutableAddressor: return .functionAccessorMutableaddress
            case .swiftAccessorAddressor: return .functionAccessorAddress
            case .swiftSubscript: return .functionSubscript
            case .swiftInfixOperator: return .functionOperatorInfix
            case .swiftPrefixOperator: return .functionOperatorPrefix
            case .swiftPostfixOperator: return .functionOperatorPostfix
            case .swiftGenericTypeParam: return .genericTypeParam
            case .swiftAssociatedtype: return .associatedtype
            case .swiftExtensionOfClass: return .extensionClass
            case .swiftExtensionOfStruct: return .extensionStruct
            case .swiftExtensionOfProtocol: return .extensionProtocol
            case .swiftExtensionOfEnum: return .extensionEnum
            default: break
            }

            switch kind {
            case .module: return .module
            case .enum: return .enum
            case .struct: return .struct
            case .class: return .class
            case .protocol: return .protocol
            case .extension: return .extension
            case .typealias: return .typealias
            case .function: return .functionFree
            case .variable: return .varGlobal
            case .enumConstant: return .enumelement
            case .instanceMethod: return .functionMethodInstance
            case .classMethod: return .functionMethodClass
            case .staticMethod: return .functionMethodStatic
            case .instanceProperty: return .varInstance
            case .classProperty: return .varClass
            case .staticProperty: return .varStatic
            case .constructor: return .functionConstructor
            case .destructor: return .functionDestructor
            case .parameter: return .varParameter
            default: return nil
            }
        }
    }
}
