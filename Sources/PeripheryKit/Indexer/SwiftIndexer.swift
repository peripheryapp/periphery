import Foundation
import PathKit
import SwiftSyntax
import SwiftIndexStore

final class SwiftIndexer {
    static func make(storePath: String, sourceFiles: Set<Path>, graph: SourceGraph) throws -> Self {
        let storeURL = URL(fileURLWithPath: storePath)

        return self.init(
            sourceFiles: sourceFiles,
            graph: graph,
            indexStore: try IndexStore.open(store: storeURL, lib: .open()),
            logger: inject(),
            configuration: inject())
    }

    private let sourceFiles: Set<Path>
    private let graph: SourceGraph
    private let logger: Logger
    private let configuration: Configuration
    private let indexStore: IndexStore

    required init(
        sourceFiles: Set<Path>,
        graph: SourceGraph,
        indexStore: IndexStore,
        logger: Logger,
        configuration: Configuration
    ) {
        self.sourceFiles = sourceFiles
        self.graph = graph
        self.logger = logger
        self.configuration = configuration
        self.indexStore = indexStore
    }

    func perform() throws {
        var jobs = [Job]()
        let excludedPaths = configuration.indexExcludeSourceFiles

        try indexStore.forEachUnits(includeSystem: false) { unit -> Bool in
            guard let filePath = try indexStore.mainFilePath(for: unit) else { return true }

            let file = Path(filePath)

            guard !excludedPaths.contains(file) else {
                self.logger.debug("[index:swift:exclude] \(file.string)")
                return true
            }

            if sourceFiles.contains(file) {
                jobs.append(
                    Job(
                        file: file,
                        unit: unit,
                        graph: graph,
                        indexStore: indexStore,
                        logger: logger,
                        configuration: configuration
                    )
                )
            }

            return true
        }

        try JobPool<Void>().forEach(jobs) { job in
            let elapsed = try Benchmark.measure {
                try job.perform()
            }

            self.logger.debug("[index:swift] \(job.file) (\(elapsed)s)")
        }

        graph.identifyRootDeclarations()
        graph.identifyRootReferences()
    }

    // MARK: - Private

    private class Job {
        let file: Path

        private let unit: IndexStoreUnit
        private let graph: SourceGraph
        private let logger: Logger
        private let configuration: Configuration
        private let indexStore: IndexStore

        required init(
            file: Path,
            unit: IndexStoreUnit,
            graph: SourceGraph,
            indexStore: IndexStore,
            logger: Logger,
            configuration: Configuration
        ) {
            self.file = file
            self.unit = unit
            self.graph = graph
            self.logger = logger
            self.configuration = configuration
            self.indexStore = indexStore
        }

        func perform() throws {
            var decls: [Declaration] = []

            try indexStore.forEachRecordDependencies(for: unit) { dependency in
                guard case let .record(record) = dependency else { return true }

                try indexStore.forEachOccurrences(for: record) { occurrence in
                    guard occurrence.symbol.language == .swift,
                          let usr = occurrence.symbol.usr,
                          let location = transformLocation(occurrence.location)
                          else { return true }

                    if !occurrence.roles.intersection([.definition, .declaration]).isEmpty {
                        if let decl = try parseDeclaration(occurrence, usr, location) {
                            decls.append(decl)
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

            establishDeclarationHierarchy()
            associateDanglingReferences(with: decls)

            let syntax = try SyntaxParser.parse(file.url)
            let locationConverter = SourceLocationConverter(file: file.string, tree: syntax)
            try identifyMetadata(for: decls, syntax: syntax, locationConverter: locationConverter)
            try identifyUnusedParameters(for: decls.filter { $0.kind.isFunctionKind }, syntax: syntax, locationConverter: locationConverter)
        }

        private var childDeclsByParentUsr: [String: Set<Declaration>] = [:]
        private var referencedDeclsByUsr: [String: Set<Reference>] = [:]
        private var referencedUsrsByDecl: [Declaration: [Reference]] = [:]
        private var danglingReferences: [Reference] = []

        private func establishDeclarationHierarchy() {
            graph.mutating {
                for (parent, decls) in childDeclsByParentUsr {
                    guard let parentDecl = graph.explicitDeclaration(withUsr: parent) else {
                        continue
                    }

                    for decl in decls {
                        decl.parent = parentDecl
                    }

                    parentDecl.declarations.formUnion(decls)
                }

                for (usr, references) in referencedDeclsByUsr {
                    guard let decl = graph.explicitDeclaration(withUsr: usr) else {
                        danglingReferences.append(contentsOf: references)
                        continue
                    }

                    for reference in references {
                        reference.parent = decl

                        if reference.isRelated {
                            decl.related.insert(reference)
                        } else {
                            decl.references.insert(reference)
                        }
                    }
                }

                for (decl, refs) in referencedUsrsByDecl {
                    for ref in refs {
                        ref.parent = decl

                        if ref.isRelated {
                            decl.related.insert(ref)
                        } else {
                            decl.references.insert(ref)
                        }
                    }
                }
            }
        }

        // Workaround for https://bugs.swift.org/browse/SR-13766
        private func associateDanglingReferences(with decls: [Declaration]) {
            guard !danglingReferences.isEmpty else { return }

            let explicitDecls = decls.filter { !$0.isImplicit }
            let declsByLocation = explicitDecls.lazy.map { ($0.location, $0) }.reduce(into: [SourceLocation: [Declaration]]()) { (result, tuple) in
                result[tuple.0, default: []].append(tuple.1)
            }
            let declsByLine = explicitDecls.lazy.map { ($0.location.line, $0) }.reduce(into: [Int64: [Declaration]]()) { (result, tuple) in
                result[tuple.0, default: []].append(tuple.1)
            }

            for ref in danglingReferences {
                guard let candidateDecls = declsByLocation[ref.location] ?? declsByLine[ref.location.line] else { continue }

                // The vast majority of the time there will only be a single declaration for this location,
                // however it is possible for there to be more than one. In that case, first attempt to associate with
                // a decl without a parent, as the reference may be a related type of a class/struct/etc.
                if let decl = candidateDecls.first(where: { $0.parent == nil }) {
                    ref.parent = decl

                    if ref.isRelated {
                        decl.related.insert(ref)
                    } else {
                        decl.references.insert(ref)
                    }
                } else if let decl = candidateDecls.first { // Fallback to using the first decl.
                    ref.parent = decl

                    if ref.isRelated {
                        decl.related.insert(ref)
                    } else {
                        decl.references.insert(ref)
                    }
                }
            }
        }

        private func identifyMetadata(
            for decls: [Declaration],
            syntax: SourceFileSyntax,
            locationConverter: SourceLocationConverter
        ) throws {
            let declsByLocation = decls.reduce(into: [SourceLocation: Declaration]()) { (result, decl) in
                result[decl.location] = decl
            }

            let result = try MetadataParser.parse(
                file: file,
                syntax: syntax,
                locationConverter: locationConverter)

            if result.fileCommands.contains(.ignoreAll) {
                decls.forEach { graph.ignore($0) }
            }

            for metadata in result.metadata {
                guard let decl = declsByLocation[metadata.location] else {
                    // The declaration may not exist if the code was not compiled due to build conditions, e.g #if.
                    continue
                }

                if let accessibility = metadata.accessibility {
                    decl.accessibility = (accessibility, true)
                }

                decl.attributes = Set(metadata.attributes)
                decl.modifiers = Set(metadata.modifiers)
                decl.commentCommands = Set(metadata.commentCommands)

                if decl.commentCommands.contains(.ignore) {
                    ignoreHierarchy(Set([decl]))
                }
            }
        }

        private func ignoreHierarchy(_ decls: Set<Declaration>) {
            decls.forEach {
                graph.ignore($0)
                ignoreHierarchy($0.declarations)
            }
        }

        private func identifyUnusedParameters(
            for decls: [Declaration],
            syntax: SourceFileSyntax,
            locationConverter: SourceLocationConverter
        ) throws {
            let functionDelcsByLocation = decls.filter { $0.kind.isFunctionKind }.map { ($0.location, $0) }.reduce(into: [SourceLocation: Declaration]()) { $0[$1.0] = $1.1 }

            let analyzer = UnusedParameterAnalyzer()
            let paramsByFunction = try analyzer.analyze(
                file: file,
                syntax: syntax,
                locationConverter: locationConverter,
                parseProtocols: true)

            for (function, params) in paramsByFunction {
                guard let functionDecl = functionDelcsByLocation[function.location] else {
                    throw PeripheryKitError.swiftIndexingError(message: "Failed to associate indexed function for parameter function '\(function.name)' at \(function.location)")
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

                    if ignoredParamNames.contains(param.name) {
                        graph.ignore(paramDecl)
                    }
                }
            }
        }

        private func parseDeclaration(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation
        ) throws -> Declaration? {
            guard let kind = transformDeclarationKind(occurrence.symbol.kind, occurrence.symbol.subKind) else {
                throw PeripheryKitError.swiftIndexingError(message: "Failed to transform IndexStore kind: \(occurrence.symbol)")
            }

            guard kind != .varParameter else {
                // Ignore indexed parameters as unused parameter identification is performed separately using SwiftSyntax.
                return nil
            }

            let decl = Declaration(kind: kind, usr: occurrenceUsr, location: location)
            decl.name = occurrence.symbol.name
            decl.isImplicit = occurrence.roles.contains(.implicit)

            if decl.isImplicit {
                decl.markRetained(reason: .implicit)
            }

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if !rel.roles.intersection([.childOf]).isEmpty {
                    if let parentUsr = rel.symbol.usr {
                        self.childDeclsByParentUsr[parentUsr, default: []].insert(decl)
                    }
                }

                if !rel.roles.intersection([.overrideOf]).isEmpty {
                    // ```
                    // class A { func f() {} }
                    // class B: A { override func f() {} }
                    // ```
                    // `B.f` is `overrideOf` `A.f`
                    // (B.f).relations has A.f
                    // B.f references A.f
                    let baseFunc = rel.symbol

                    if let baseFuncUsr = baseFunc.usr {
                        guard let refKind = transformReferenceKind(baseFunc.kind, baseFunc.subKind) else {
                            logger.error("Failed to transform ref kind")
                            return false
                        }

                        let reference = Reference(kind: refKind, usr: baseFuncUsr, location: decl.location)
                        reference.name = baseFunc.name
                        reference.isRelated = true

                        graph.add(reference)
                        self.referencedUsrsByDecl[decl, default: []].append(reference)
                    }
                }

                if !rel.roles.intersection([.baseOf, .calledBy, .extendedBy, .containedBy]).isEmpty {
                    // ```
                    // class A {}
                    // class B: A {}
                    // ```
                    // `A` is `baseOf` `B`
                    // A.relations has B as `baseOf`
                    // B referenes A
                    let referencer = rel.symbol

                    if let referencerUsr = referencer.usr {
                        guard let refKind = transformReferenceKind(occurrence.symbol.kind, occurrence.symbol.subKind) else {
                            logger.error("Failed to transform ref kind")
                            return false
                        }

                        let reference = Reference(kind: refKind, usr: decl.usr, location: decl.location)
                        reference.name = decl.name

                        if rel.roles.contains(.baseOf) {
                            reference.isRelated = true
                        }

                        graph.add(reference)
                        self.referencedDeclsByUsr[referencerUsr, default: []].insert(reference)
                    }
                }

                return true
            }

            graph.add(decl)
            return decl
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

                    if let baseFuncUsr = baseFunc.usr {
                        guard let refKind = transformReferenceKind(baseFunc.kind, baseFunc.subKind) else {
                            logger.error("Failed to transform ref kind")
                            return false
                        }

                        let reference = Reference(kind: refKind, usr: baseFuncUsr, location: location)
                        reference.name = baseFunc.name
                        reference.isRelated = true

                        graph.add(reference)
                        self.referencedDeclsByUsr[occurrenceUsr, default: []].insert(reference)
                        refs.append(reference)
                    }
                }

                return true
            }

            refs.forEach { graph.add($0) }
        }

        private func parseReference(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation
        ) throws {
            guard let kind = transformReferenceKind(occurrence.symbol.kind, occurrence.symbol.subKind) else {
                throw PeripheryKitError.swiftIndexingError(message: "Failed to transform IndexStore kind: \(occurrence.symbol)")
            }

            guard kind != .varParameter else {
                // Ignore indexed parameters as unused parameter identification is performed separately using SwiftSyntax.
                return
            }

            var refs = [Reference]()

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if !rel.roles.intersection([.baseOf, .calledBy, .containedBy, .extendedBy]).isEmpty {
                    // ```
                    // class A {}
                    // class B: A {}
                    // ```
                    // `A` is `baseOf` `B`
                    // A.relations has B as `baseOf`
                    // B referenes A
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

            refs.forEach { graph.add($0) }
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
            case .swiftAccessorRead:
                logger.warn("Skip to transform swiftAccessorRead")
            case .swiftAccessorModify:
                logger.warn("Skip to transform swiftAccessorRead")
            case .none: break
            case .cxxCopyConstructor, .cxxMoveConstructor,
                 .usingTypeName, .usingValue: break
            }

            switch kind {
            case .unknown: return nil
            case .module: return .module
            case .namespace, .namespaceAlias:
                logger.warn("'namespace' is not supported on Swift")
                return nil
            case .macro:
                logger.warn("'macro' is not supported on Swift")
                return nil
            case .enum: return .enum
            case .struct: return .struct
            case .class: return .class
            case .protocol: return .protocol
            case .extension: return .extension
            case .union:
                logger.warn("'union' is not supported on Swift")
                return nil
            case .typealias: return .typealias
            case .function: return .functionFree
            case .variable: return .varGlobal
            case .field:
                logger.warn("'field' is not supported on Swift")
                return nil
            case .enumConstant: return .enumelement
            case .instanceMethod: return .functionMethodInstance
            case .classMethod: return .functionMethodClass
            case .staticMethod: return .functionMethodStatic
            case .instanceProperty: return .varInstance
            case .classProperty: return .varClass
            case .staticProperty: return .varStatic
            case .constructor: return .functionConstructor
            case .destructor: return .functionDestructor
            case .conversionFunction:
                logger.warn("'conversionFunction' is not supported on Swift")
                return nil
            case .parameter: return .varParameter
            case .using:
                logger.warn("'using' is not supported on Swift")
                return nil
            case .commentTag:
                logger.warn("'commentTag' is not supported on Swift")
                return nil
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
            case .swiftAccessorRead:
                logger.warn("Skip to transform swiftAccessorRead")
            case .swiftAccessorModify:
                logger.warn("Skip to transform swiftAccessorModify")
            case .none: break
            case .cxxCopyConstructor, .cxxMoveConstructor,
                 .usingTypeName, .usingValue: break
            }

            switch kind {
            case .unknown: return nil
            case .module: return .module
            case .namespace, .namespaceAlias:
                logger.warn("'namespace' is not supported on Swift")
                return nil
            case .macro:
                logger.warn("'macro' is not supported on Swift")
                return nil
            case .enum: return .enum
            case .struct: return .struct
            case .class: return .class
            case .protocol: return .protocol
            case .extension: return .extension
            case .union:
                logger.warn("'union' is not supported on Swift")
                return nil
            case .typealias: return .typealias
            case .function: return .functionFree
            case .variable: return .varGlobal
            case .field:
                logger.warn("'field' is not supported on Swift")
                return nil
            case .enumConstant: return .enumelement
            case .instanceMethod: return .functionMethodInstance
            case .classMethod: return .functionMethodClass
            case .staticMethod: return .functionMethodStatic
            case .instanceProperty: return .varInstance
            case .classProperty: return .varClass
            case .staticProperty: return .varStatic
            case .constructor: return .functionConstructor
            case .destructor: return .functionDestructor
            case .conversionFunction:
                logger.warn("'conversionFunction' is not supported on Swift")
                return nil
            case .parameter: return .varParameter
            case .using:
                logger.warn("'using' is not supported on Swift")
                return nil
            case .commentTag:
                logger.warn("'commentTag' is not supported on Swift")
                return nil
            }
        }
    }
}
