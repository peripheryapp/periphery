import Foundation
import PathKit
import SwiftSyntax
import SwiftIndexStore
import Shared

public final class SwiftIndexer {
    public static func make(storePath: String, sourceFiles: [Path: [String]], graph: SourceGraph) throws -> Self {
        let storeURL = URL(fileURLWithPath: storePath)

        return self.init(
            sourceFiles: sourceFiles,
            graph: graph,
            indexStore: try .open(store: storeURL, lib: .open()),
            indexStoreURL: storeURL,
            logger: inject(),
            configuration: inject())
    }

    private let sourceFiles: [Path: [String]]
    private let graph: SourceGraph
    private let logger: Logger
    private let configuration: Configuration
    private let indexStore: IndexStore
    private let indexStoreURL: URL

    required init(
        sourceFiles: [Path: [String]],
        graph: SourceGraph,
        indexStore: IndexStore,
        indexStoreURL: URL,
        logger: Logger,
        configuration: Configuration
    ) {
        self.sourceFiles = sourceFiles
        self.graph = graph
        self.indexStore = indexStore
        self.indexStoreURL = indexStoreURL
        self.logger = logger
        self.configuration = configuration
    }

    public func perform() throws {
        let excludedPaths = configuration.indexExcludeSourceFiles
        var unitsByFile: [Path: [IndexStoreUnit]] = [:]
        let allSourceFiles = Set(sourceFiles.keys)

        try indexStore.forEachUnits(includeSystem: false) { unit -> Bool in
            guard let filePath = try indexStore.mainFilePath(for: unit) else { return true }

            let file = Path(filePath)

            guard !excludedPaths.contains(file) else {
                self.logger.debug("[index:swift] Excluding \(file.string)")
                return true
            }

            if allSourceFiles.contains(file) {
                unitsByFile[file, default: []].append(unit)
            }

            return true
        }

        let indexedPaths = Set(unitsByFile.keys)
        let unindexedPaths = allSourceFiles.subtracting(indexedPaths)

        if !unindexedPaths.isEmpty {
            unindexedPaths.forEach { logger.debug("[index:swift] Source file not indexed: \($0)") }
            let targets: Set<String> = Set(unindexedPaths.flatMap { sourceFiles[$0] ?? [] })
            throw PeripheryError.unindexedTargetsError(targets: targets, indexStorePath: indexStoreURL.path)
        }

        let jobs = try unitsByFile.map { (file, units) -> Job in
            let modules = try units.reduce(into: Set<String>()) { (set, unit) in
                if let name = try indexStore.moduleName(for: unit) {
                    set.insert(name)
                }
            }
            let sourceFile = SourceFile(path: file, modules: modules)

            return Job(
                file: sourceFile,
                units: units,
                graph: graph,
                indexStore: indexStore,
                logger: logger,
                configuration: configuration
            )
        }

        try JobPool<Void>().forEach(jobs) { job in
            let elapsed = try Benchmark.measure {
                try job.perform()
            }

            self.logger.debug("[index:swift] \(job.file.path) (\(elapsed)s)")
        }
    }

    // MARK: - Private

    private class Job {
        let file: SourceFile

        private let units: [IndexStoreUnit]
        private let graph: SourceGraph
        private let indexStore: IndexStore
        private let logger: Logger
        private let configuration: Configuration

        required init(
            file: SourceFile,
            units: [IndexStoreUnit],
            graph: SourceGraph,
            indexStore: IndexStore,
            logger: Logger,
            configuration: Configuration
        ) {
            self.file = file
            self.units = units
            self.graph = graph
            self.indexStore = indexStore
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

        func perform() throws {
            var rawDeclsByKey: [RawDeclaration.Key: [(RawDeclaration, [RawRelation])]] = [:]

            for unit in units {
                try indexStore.forEachRecordDependencies(for: unit) { dependency in
                    guard case let .record(record) = dependency else { return true }

                    try indexStore.forEachOccurrences(for: record) { occurrence in
                        guard occurrence.symbol.language == .swift,
                              let usr = occurrence.symbol.usr,
                              let location = transformLocation(occurrence.location)
                              else { return true }

                        if !occurrence.roles.intersection([.definition, .declaration]).isEmpty {
                            if let (decl, relations) = try parseRawDeclaration(occurrence, usr, location) {
                                rawDeclsByKey[decl.key, default: []].append((decl, relations))
                            }
                        }

                        if !occurrence.roles.intersection([.reference]).isEmpty {
                            try parseReference(occurrence, usr, location)
                        }

                        if !occurrence.roles.intersection([.implicit]).isEmpty {
                            try parseImplicit(occurrence, usr, location)
                        }

                        return true
                    }

                    return true
                }
            }

            var decls: [Declaration] = []

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
                decls.append(decl)
            }

            let multiplexingSyntaxVisitor = try MultiplexingSyntaxVisitor(file: file)
            let declarationVisitor = multiplexingSyntaxVisitor.add(DeclarationVisitor.self)
            let propertyVisitor = multiplexingSyntaxVisitor.add(PropertyVisitor.self)
            let functionVisitor = multiplexingSyntaxVisitor.add(FunctionVisitor.self)
            let conformableVisitor = multiplexingSyntaxVisitor.add(ConformableVisitor.self)
            let importVisitor = multiplexingSyntaxVisitor.add(ImportVisitor.self)

            multiplexingSyntaxVisitor.visit()

            file.importStatements = importVisitor.importStatements
            let propertyByLocation = propertyVisitor.resultsByLocation
            let functionByLocation = functionVisitor.resultsByLocation
            let conformableByLocation = conformableVisitor.resultsByLocation
            let explicitDeclarations = decls.filter { !$0.isImplicit }
            let propertyDeclarations = explicitDeclarations.filter { $0.kind.isAccessibilityModifiableVariableKind }
            let functionDeclarations = explicitDeclarations.filter { $0.kind.isAccessibilityModifiableFunctionKind }
            let conformableDeclarations = explicitDeclarations.filter { $0.kind.isDiscreteConformableKind }

            establishDeclarationHierarchy()
            associateDanglingReferences(for: explicitDeclarations)
            identifyDeclaredPropertyTypes(for: propertyDeclarations, using: propertyByLocation)
            identifyPropertyReferenceRoles(for: propertyDeclarations, using: propertyByLocation)
            identifyFunctionReferenceRoles(for: functionDeclarations, using: functionByLocation)
            identifyConformableReferenceRoles(for: conformableDeclarations, using: conformableByLocation)

            applyDeclarationMetadata(for: decls, using: declarationVisitor.results)
            identifyUnusedParameters(for: decls.filter { $0.kind.isFunctionKind }, syntaxVisitor: multiplexingSyntaxVisitor)
            applyCommentCommands(for: decls, syntaxVisitor: multiplexingSyntaxVisitor)
        }

        private var childDeclsByParentUsr: [String: Set<Declaration>] = [:]
        private var referencedDeclsByUsr: [String: Set<Reference>] = [:]
        private var referencedUsrsByDecl: [Declaration: [Reference]] = [:]
        private var danglingReferences: [Reference] = []
        private var varParameterUsrs: Set<String> = []

        private func establishDeclarationHierarchy() {
            graph.mutating {
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

                for (usr, refs) in referencedDeclsByUsr {
                    guard let decl = graph.explicitDeclaration(withUsr: usr) else {
                        danglingReferences.append(contentsOf: refs)
                        continue
                    }

                    for ref in refs {
                        associateUnsafe(ref, with: decl)
                    }
                }

                for (decl, refs) in referencedUsrsByDecl {
                    for ref in refs {
                        associateUnsafe(ref, with: decl)
                    }
                }
            }
        }

        // Workaround for https://bugs.swift.org/browse/SR-13766
        // Swift does not associate some type references with the containing declaration, resulting in references
        // with no clear parent.
        private func associateDanglingReferences(for declarations: [Declaration]) {
            guard !danglingReferences.isEmpty else { return }

            let declsByLocation = declarations
                .reduce(into: [SourceLocation: [Declaration]]()) { (result, decl) in
                    result[decl.location, default: []].append(decl)
                }
            let declsByLine = declarations
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

        // The index store does not provide type information, thus we use the declared type information from the source
        // file. This type information may be used during analysis.
        private func identifyDeclaredPropertyTypes(for decls: [Declaration], using propertiesByLocation: [SourceLocation: PropertyVisitor.Result]) {
            for decl in decls {
                guard let property = propertiesByLocation[decl.location] else {
                    logger.debug("[index:swift] Failed to identify property declaration at '\(decl.location)' for property type identification.")
                    continue
                }

                graph.mutating {
                    decl.declaredType = property.type
                }
            }
        }

        // Identify the role of references from property declarations.
        private func identifyPropertyReferenceRoles(for decls: [Declaration], using propertiesByLocation: [SourceLocation: PropertyVisitor.Result]) {
            for decl in decls {
                guard let property = propertiesByLocation[decl.location] else {
                    logger.debug("[index:swift] Failed to identify property declaration at '\(decl.location)' for reference role identification.")
                    continue
                }

                graph.mutating {
                    for ref in decl.references {
                        if property.typeLocations.contains(ref.location) {
                            ref.role = .varType
                        }
                    }
                }
            }
        }

        // Identify the role of references from function declarations.
        private func identifyFunctionReferenceRoles(for decls: [Declaration], using functionsByLocation: [SourceLocation: FunctionVisitor.Result]) {
            for decl in decls {
                guard let function = functionsByLocation[decl.location] else {
                    logger.debug("[index:swift] Failed to identify function declaration at '\(decl.location)' for reference role identification.")
                    continue
                }

                graph.mutating {
                    for ref in decl.references {
                        if function.returnTypeLocations.contains(ref.location) {
                            ref.role = .returnType
                        } else if function.parameterTypeLocations.contains(ref.location) {
                            ref.role = .parameterType
                        } else if function.genericParameterLocations.contains(ref.location) {
                            ref.role = .genericParameterType
                        } else if function.genericConformanceRequirementLocations.contains(ref.location) {
                            ref.role = .genericRequirementType
                        }
                    }
                }
            }
        }

        // Identify the role of references from conformable declarations.
        private func identifyConformableReferenceRoles(for decls: [Declaration], using conformablesByLocation: [SourceLocation: ConformableVisitor.Result]) {
            for decl in decls {
                guard let conformable = conformablesByLocation[decl.location] else {
                    logger.debug("[index:swift] Failed to identify conformable declaration at '\(decl.location)' for reference role identification.")
                    continue
                }

                graph.mutating {
                    for ref in decl.references {
                        if conformable.genericParameterLocations.contains(ref.location) {
                            ref.role = .genericParameterType
                        } else if conformable.genericConformanceRequirementLocations.contains(ref.location) {
                            ref.role = .genericRequirementType
                        }
                    }
                }
            }
        }

        private func applyCommentCommands(for decls: [Declaration], syntaxVisitor: MultiplexingSyntaxVisitor) {
            let fileCommands = CommentCommand.parseCommands(in: syntaxVisitor.syntax.leadingTrivia)

            if fileCommands.contains(.ignoreAll) {
                retainHierarchy(decls)
            } else {
                for decl in decls {
                    if decl.commentCommands.contains(.ignore) {
                        retainHierarchy([decl])
                    }
                }
            }
        }

        private func applyDeclarationMetadata(for decls: [Declaration], using declarationMetadatas: [DeclarationVisitor.Result]) {
            let declsByLocation = decls.reduce(into: [SourceLocation: [Declaration]]()) { (result, decl) in
                result[decl.location, default: []].append(decl)
            }

            for metadata in declarationMetadatas {
                guard let decls = declsByLocation[metadata.location] else {
                    // The declaration may not exist if the code was not compiled due to build conditions, e.g #if.
                    logger.debug("[index:swift] Expected declaration at \(metadata.location)")
                    continue
                }

                for decl in decls {
                    if let accessibility = metadata.accessibility {
                        decl.accessibility = .init(value: accessibility, isExplicit: true)
                    }

                    decl.attributes = Set(metadata.attributes)
                    decl.modifiers = Set(metadata.modifiers)
                    decl.commentCommands = Set(metadata.commentCommands)
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
            graph.mutating {
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

        private func identifyUnusedParameters(for decls: [Declaration], syntaxVisitor: MultiplexingSyntaxVisitor) {
            let functionDelcsByLocation = decls.filter { $0.kind.isFunctionKind }.map { ($0.location, $0) }.reduce(into: [SourceLocation: Declaration]()) { $0[$1.0] = $1.1 }

            let analyzer = UnusedParameterAnalyzer()
            let paramsByFunction = analyzer.analyze(
                file: file,
                syntax: syntaxVisitor.syntax,
                locationConverter: syntaxVisitor.locationConverter,
                parseProtocols: true)

            for (function, params) in paramsByFunction {
                guard let functionDecl = functionDelcsByLocation[function.location] else {
                    // The declaration may not exist if the code was not compiled due to build conditions, e.g #if.
                    logger.debug("[index:swift] Failed to associate indexed function for parameter function '\(function.name)' at \(function.location).")
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

                for param in params {
                    let paramDecl = param.declaration
                    paramDecl.parent = functionDecl
                    functionDecl.unusedParameters.insert(paramDecl)
                    graph.add(paramDecl)

                    if ignoredParamNames.contains(param.name) ||
                        (functionDecl.isObjcAccessible && configuration.retainObjcAccessible) {
                        graph.markRetained(paramDecl)
                    }
                }
            }
        }

        private func parseRawDeclaration(
            _ occurrence: IndexStoreOccurrence,
            _ usr: String,
            _ location: SourceLocation
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

                        graph.add(reference)
                        self.referencedUsrsByDecl[decl, default: []].append(reference)
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
                            self.referencedDeclsByUsr[referencerUsr, default: []].insert(reference)
                        }
                    }
                }
            }
        }

        private func parseImplicit(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation
        ) throws {
            var refs = [Reference]()

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if !rel.roles.intersection([.overrideOf]).isEmpty {
                    let baseFunc = rel.symbol

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = transformReferenceKind(baseFunc.kind, baseFunc.subKind) {
                        let reference = Reference(kind: baseFuncKind, usr: baseFuncUsr, location: location)
                        reference.name = baseFunc.name
                        reference.isRelated = true

                        self.referencedDeclsByUsr[occurrenceUsr, default: []].insert(reference)
                        refs.append(reference)
                    }
                }

                return true
            }

            graph.mutating {
                refs.forEach { graph.addUnsafe($0) }
            }
        }

        private func parseReference(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation
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
                        self.referencedDeclsByUsr[referencerUsr, default: []].insert(ref)
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
                danglingReferences.append(ref)
            }

            graph.mutating {
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
