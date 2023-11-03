import Foundation
import SwiftSyntax
import SwiftIndexStore
import SystemPackage
import Shared

public final class SwiftIndexer: Indexer {
    private let sourceFiles: [FilePath: Set<IndexTarget>]
    private let graph: SourceGraph
    private let logger: ContextualLogger
    private let configuration: Configuration
    private let indexStorePaths: [FilePath]
    private let currentFilePath = FilePath.current

    public required init(
        sourceFiles: [FilePath: Set<IndexTarget>],
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
        let allSourceFiles = Set(sourceFiles.keys)
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: allSourceFiles)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        let unitsByFile = try JobPool(jobs: indexStorePaths)
            .flatMap { [logger, currentFilePath] indexStorePath in
                logger.debug("Reading \(indexStorePath)")
                let indexStore = try IndexStore.open(store: URL(fileURLWithPath: indexStorePath.string), lib: .open())
                let units = indexStore.units(includeSystem: false)

                return try units.compactMap { unit  -> (FilePath, IndexStore, IndexStoreUnit)? in
                    guard let filePath = try indexStore.mainFilePath(for: unit) else { return nil }

                    let file = FilePath.makeAbsolute(filePath, relativeTo: currentFilePath)

                    if includedFiles.contains(file) {
                        return (file, indexStore, unit)
                    }

                    return nil
                }
            }
            .reduce(into: [FilePath: [(IndexStore, IndexStoreUnit)]](), { result, tuple in
                let (file, indexStore, unit) = tuple
                result[file, default: []].append((indexStore, unit))
            })

        let indexedFiles = Set(unitsByFile.keys)
        let unindexedFiles = allSourceFiles.subtracting(excludedFiles).subtracting(indexedFiles)

        if !unindexedFiles.isEmpty {
            unindexedFiles.forEach { logger.debug("Source file not indexed: \($0)") }
            let targets = unindexedFiles.flatMapSet { sourceFiles[$0] ?? [] }.mapSet { $0.name }
            throw PeripheryError.unindexedTargetsError(targets: targets, indexStorePaths: indexStorePaths)
        }

        let jobs = unitsByFile.map { (file, units) -> Job in
            return Job(
                file: file,
                units: units,
                graph: graph,
                logger: logger,
                configuration: configuration
            )
        }

        let phaseOneLogger = logger.contextualized(with: "phase:one")
        let phaseOneInterval = logger.beginInterval("index:swift:phase:one")

        try JobPool(jobs: jobs).forEach { job in
            let elapsed = try Benchmark.measure {
                try job.phaseOne()
            }

            phaseOneLogger.debug("\(job.file) (\(elapsed)s)")
        }

        logger.endInterval(phaseOneInterval)

        let phaseTwoLogger = logger.contextualized(with: "phase:two")
        let phaseTwoInterval = logger.beginInterval("index:swift:phase:two")

        try JobPool(jobs: jobs).forEach { job in
            let elapsed = try Benchmark.measure {
                try job.phaseTwo()
            }

            phaseTwoLogger.debug("\(job.file) (\(elapsed)s)")
        }

        logger.endInterval(phaseTwoInterval)
    }

    // MARK: - Private

    private class Job {
        let file: FilePath

        private let units: [(IndexStore, IndexStoreUnit)]
        private let graph: SourceGraph
        private let logger: ContextualLogger
        private let configuration: Configuration
        private var sourceFile: SourceFile?

        required init(
            file: FilePath,
            units: [(IndexStore, IndexStoreUnit)],
            graph: SourceGraph,
            logger: ContextualLogger,
            configuration: Configuration

        ) {
            self.file = file
            self.units = units
            self.graph = graph
            self.logger = logger
            self.configuration = configuration
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
            var references: Set<Reference> = []

            for (indexStore, unit) in units {
                try indexStore.forEachRecordDependencies(for: unit) { dependency in
                    guard case let .record(record) = dependency else { return true }

                    try indexStore.forEachOccurrences(for: record, language: .swift) { occurrence in
                        guard let usr = occurrence.symbol.usr,
                              let location = try transformLocation(occurrence.location)
                              else { return true }

                        if !occurrence.roles.intersection([.definition, .declaration]).isEmpty {
                            if let (decl, relations) = try parseRawDeclaration(occurrence, usr, location, indexStore) {
                                rawDeclsByKey[decl.key, default: []].append((decl, relations))
                            }
                        }

                        if occurrence.roles.contains(.reference) {
                            references.formUnion(try parseReference(occurrence, usr, location, indexStore))
                        }

                        if occurrence.roles.contains(.implicit) {
                            references.formUnion(try parseImplicit(occurrence, usr, location, indexStore))
                        }

                        return true
                    }

                    return true
                }
            }

            var newDeclarations: Set<Declaration> = []

            for (key, values) in rawDeclsByKey {
                let usrs = values.mapSet { $0.0.usr }
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
                references.formUnion(try parseDeclaration(decl, relations))

                newDeclarations.insert(decl)
                declarations.append(decl)
            }

            graph.withLock {
                graph.addUnsafe(references)
                graph.addUnsafe(newDeclarations)
            }

            establishDeclarationHierarchy()
        }

        /// Phase two associates latent references, and performs other actions that depend on the completed source graph.
        func phaseTwo() throws {
            let sourceFile = try getSourceFile()
            let multiplexingSyntaxVisitor = try MultiplexingSyntaxVisitor(file: sourceFile)
            let declarationSyntaxVisitor = multiplexingSyntaxVisitor.add(DeclarationSyntaxVisitor.self)
            let importSyntaxVisitor = multiplexingSyntaxVisitor.add(ImportSyntaxVisitor.self)

            multiplexingSyntaxVisitor.visit()

            sourceFile.importStatements = importSyntaxVisitor.importStatements

            associateLatentReferences()
            associateDanglingReferences()
            visitDeclarations(using: declarationSyntaxVisitor)
            identifyUnusedParameters(using: multiplexingSyntaxVisitor)
            applyCommentCommands(using: multiplexingSyntaxVisitor)
        }

        // MARK: - Private

        private var declarations: [Declaration] = []
        private var childDeclsByParentUsr: [String: Set<Declaration>] = [:]
        private var referencesByUsr: [String: Set<Reference>] = [:]
        private var danglingReferences: [Reference] = []
        private var varParameterUsrs: Set<String> = []

        private func getSourceFile() throws -> SourceFile {
            if let sourceFile { return sourceFile }

            let modules = try units.reduce(into: Set<String>()) { (set, tuple) in
                let (indexStore, unit) = tuple
                if let name = try indexStore.moduleName(for: unit) {
                    set.insert(name)
                }
            }

            let sourceFile = SourceFile(path: file, modules: modules)
            self.sourceFile = sourceFile
            return sourceFile
        }

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
        // with no clear parent. Property references are one example: https://github.com/apple/swift/issues/56163
        private func associateDanglingReferences() {
            guard !danglingReferences.isEmpty else { return }

            let explicitDeclarations = declarations.filter { !$0.isImplicit }
            let declsByLocation = explicitDeclarations
                .reduce(into: [SourceLocation: [Declaration]]()) { (result, decl) in
                    result[decl.location, default: []].append(decl)
                }
            let declsByLine = explicitDeclarations
                .reduce(into: [Int: [Declaration]]()) { (result, decl) in
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
            }
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
                decl.hasCapitalSelfFunctionCall = result.hasCapitalSelfFunctionCall
                decl.hasGenericFunctionReturnedMetatypeParameters = result.hasGenericFunctionReturnedMetatypeParameters

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
                    } else if result.variableInitFunctionCallLocations.contains(ref.location) {
                        ref.role = .variableInitFunctionCall
                    } else if result.functionCallMetatypeArgumentLocations.contains(ref.location) {
                        ref.role = .functionCallMetatypeArgument
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
                file: syntaxVisitor.sourceFile,
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
        ) throws -> Set<Reference> {
            var references: Set<Reference> = []

            for rel in relations {
                if rel.roles.contains(.childOf) {
                    if let parentUsr = rel.symbol.usr {
                        self.childDeclsByParentUsr[parentUsr, default: []].insert(decl)
                    }
                }

                if rel.roles.contains(.overrideOf) {
                    let baseFunc = rel.symbol

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = transformDeclarationKind(baseFunc.kind, baseFunc.subKind) {
                        let reference = Reference(
                            kind: baseFuncKind,
                            usr: baseFuncUsr,
                            location: decl.location,
                            isRelated: true
                        )
                        reference.name = baseFunc.name
                        reference.parent = decl
                        decl.related.insert(reference)
                        references.insert(reference)
                    }
                }

                if !rel.roles.intersection([.baseOf, .calledBy, .extendedBy, .containedBy]).isEmpty {
                    let referencer = rel.symbol

                    if let referencerUsr = referencer.usr {
                        for usr in decl.usrs {
                            let reference = Reference(
                                kind: decl.kind,
                                usr: usr,
                                location: decl.location,
                                isRelated: rel.roles.contains(.baseOf)
                            )
                            reference.name = decl.name
                            references.insert(reference)
                            self.referencesByUsr[referencerUsr, default: []].insert(reference)
                        }
                    }
                }
            }

            return references
        }

        private func parseImplicit(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation,
            _ indexStore: IndexStore
        ) throws -> [Reference] {
            var refs = [Reference]()

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if rel.roles.contains(.overrideOf) {
                    let baseFunc = rel.symbol

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = transformDeclarationKind(baseFunc.kind, baseFunc.subKind) {
                        let reference = Reference(
                            kind: baseFuncKind,
                            usr: baseFuncUsr,
                            location: location,
                            isRelated: true
                        )
                        reference.name = baseFunc.name
                        self.referencesByUsr[occurrenceUsr, default: []].insert(reference)
                        refs.append(reference)
                    }
                }

                return true
            }

            return refs
        }

        private func parseReference(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation,
            _ indexStore: IndexStore
        ) throws -> [Reference] {
            guard let kind = transformDeclarationKind(occurrence.symbol.kind, occurrence.symbol.subKind)
                  else { return [] }

            guard kind != .varParameter else {
                // Ignore indexed parameters as unused parameter identification is performed separately using SwiftSyntax.
                return []
            }

            var refs = [Reference]()

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if !rel.roles.intersection([.baseOf, .calledBy, .containedBy, .extendedBy]).isEmpty {
                    let referencer = rel.symbol

                    if let referencerUsr = referencer.usr {
                        let ref = Reference(
                            kind: kind,
                            usr: occurrenceUsr,
                            location: location,
                            isRelated: rel.roles.contains(.baseOf)
                        )
                        ref.name = occurrence.symbol.name
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

            return refs
        }

        private func transformLocation(_ input: IndexStoreOccurrence.Location) throws -> SourceLocation? {
            return SourceLocation(file: try getSourceFile(), line: Int(input.line), column: Int(input.column))
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
    }
}
