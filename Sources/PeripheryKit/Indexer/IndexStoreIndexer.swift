import Foundation
import PathKit
import SwiftSyntax
import TSCBasic

final class IndexStoreIndexer: TypeIndexer {
    static func make(buildPlan: BuildPlan, graph: SourceGraph) throws -> Self {
        let configuration = inject(Configuration.self)
        guard let indexStorePathString = configuration.indexStorePath else {
            throw PeripheryKitError.indexStoreError(message: "-index-store-path option is required")
        }
        let indexStorePath = AbsolutePath(indexStorePathString)
        return self.init(buildPlan: buildPlan,
                         graph: graph,
                         indexStore: try IndexStore.open(store: indexStorePath, api: IndexStoreAPI.make()),
                         logger: inject(),
                         featureManager: inject(),
                         configuration: inject())
    }

    private let buildPlan: BuildPlan
    private let graph: SourceGraph
    private let logger: Logger
    private let featureManager: FeatureManager
    private let configuration: Configuration
    private let indexStore: IndexStore

    required init(buildPlan: BuildPlan,
                  graph: SourceGraph,
                  indexStore: IndexStore,
                  logger: Logger,
                  featureManager: FeatureManager,
                  configuration: Configuration) {
        self.buildPlan = buildPlan
        self.graph = graph
        self.logger = logger
        self.featureManager = featureManager
        self.configuration = configuration
        self.indexStore = indexStore
    }

    func perform() throws {

        var jobs = [Job]()

        indexStore.forEachUnits { unit -> Bool in
            jobs.append(
                Job(
                    unit: unit, buildPlan: buildPlan, graph: graph, indexStore: indexStore,
                    logger: logger, featureManager: featureManager, configuration: configuration
                )
            )
            return true
        }

        try JobPool<Void>().forEach(jobs) { job in
            let elapsed = try Benchmark.measure {
                try job.perform()
            }

            self.logger.debug("[index:swift] \(job.unit.name) (\(elapsed)s)")
        }

        graph.identifyRootDeclarations()
        graph.identifyRootReferences()
    }

    // MARK: - Private

    private class Job {

        let unit: IndexStoreUnit

        private let buildPlan: BuildPlan
        private let graph: SourceGraph
        private let logger: Logger
        private let featureManager: FeatureManager
        private let configuration: Configuration
        private let indexStore: IndexStore


        private let sourceKit = SourceKit.make()
        private lazy var indexStructure = Cache { [sourceKit] (sourceFile: SourceFile) -> [[String: Any]] in
            let substructure = try sourceKit.editorOpenSubstructure(sourceFile)
            return substructure[SourceKit.Key.substructure.rawValue] as? [[String: Any]] ?? []
        }

        private lazy var shouldIndex = Cache { [buildPlan, configuration] (path: String) -> Bool in
            let isExcluded = { configuration.indexExcludeSourceFiles.contains(where: { $0.path.string == path }) }
            let isInTarget = {
                try buildPlan.targets.contains(where: {
                    try $0.sourceFiles().contains(where: { $0.path.string == path })
                })
            }
            return try !isExcluded() && isInTarget()
        }

        required init(unit: IndexStoreUnit,
                      buildPlan: BuildPlan,
                      graph: SourceGraph,
                      indexStore: IndexStore,
                      logger: Logger,
                      featureManager: FeatureManager,
                      configuration: Configuration) {
            self.unit = unit
            self.buildPlan = buildPlan
            self.graph = graph
            self.logger = logger
            self.featureManager = featureManager
            self.configuration = configuration
            self.indexStore = indexStore
        }

        func perform() throws {

            var decls: [(decl: Declaration, structures: [[String: Any]])] = []
            try indexStore.forEachOccurrences(for: unit) { occ in
                guard occ.symbol.language == .swift, !occ.location.isSystem else { return true }
                let shouldIndex = try buildPlan.targets.contains(where: {
                    try $0.sourceFiles().contains(where: { $0.path.string == occ.location.path })
                })

                guard shouldIndex else { return true }
                if !occ.roles.intersection([.definition, .declaration]).isEmpty {
                    var rawStructures: [[String: Any]] = []
                    if featureManager.isEnabled(.determineAccessibilityFromStructure) {
                        let file = SourceFile(path: Path(occ.location.path))
                        rawStructures = try self.indexStructure.get(file)
                    }
                    let decl = try _parseDecl(occ, rawStructures)
                    graph.add(decl)
                    decls.append((decl, rawStructures))
                }

                if !occ.roles.intersection([.reference]).isEmpty {
                    let refs = try _parseReference(occ)
                    for ref in refs {
                        graph.add(ref)
                    }
                }

                if !occ.roles.intersection([.implicit]).isEmpty {
                    let refs = try _parseImplicit(occ)
                    for ref in refs {
                        graph.add(ref)
                    }
                }
                return true
            }

            do {
                // Make relationships between declarations

                for (parent, decls) in childDeclsByParentUsr {
                    guard let parentDecl = graph.declaration(withUsr: parent) else {
                        continue
                    }
                    for decl in decls {
                        decl.parent = parentDecl
                    }
                    parentDecl.declarations.formUnion(decls)
                }

                for (usr, references) in referencedDeclsByUsr {
                    guard let decl = graph.declaration(withUsr: usr) else {
                        continue
                    }
                    for reference in references {
                        reference.parent = decl
                        graph.add(reference)
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
                        graph.add(ref)
                        if ref.isRelated {
                            decl.related.insert(ref)
                        } else {
                            decl.references.insert(ref)
                        }
                    }
                }
            }

            for (decl, structure) in decls {
                guard decl.parent == nil else { continue }
                try _parseIndexedStructure(decl, structure)
            }
        }

        private var childDeclsByParentUsr: [String: Set<Declaration>] = [:]
        private var referencedDeclsByUsr: [String: Set<Reference>] = [:]
        private var referencedUsrsByDecl: [Declaration: [Reference]] = [:]

        private func _parseDecl(
            _ occ: IndexStoreOccurrence,
            _ indexedStructure: [[String: Any]]
        ) throws -> Declaration {
            guard let kind = transformDeclarationKind(occ.symbol.kind, occ.symbol.subKind) else {
                throw PeripheryKitError.swiftIndexingError(message: "Failed to transform IndexStore kind into SourceKit kind: \(occ.symbol)")
            }
            let loc = transformLocation(occ.location)
            let decl = Declaration(kind: kind, usr: occ.symbol.usr, location: loc)
            decl.name = occ.symbol.name

            indexStore.forEachRelations(for: occ) { rel -> Bool in
                // Note: Skip adding accessor in variable children to avoid circurlar reference
                // Expected graph is
                // ```
                // variable.getter  ──> variable
                // variable.settter ──> variable
                // ```
                // If there is no guard statement,
                // ```
                // variable <──┬────> variable.getter
                //             └────> variable.setter
                // ```
                if !rel.roles.intersection([.childOf]).isEmpty && !rel.roles.contains(.accessorOf) {
                    let parent = indexStore.getSymbol(for: rel.symbolRef)
                    if self.childDeclsByParentUsr[parent.usr] != nil {
                        self.childDeclsByParentUsr[parent.usr]?.insert(decl)
                    } else {
                        self.childDeclsByParentUsr[parent.usr] = [decl]
                    }
                }
                if !rel.roles.intersection([.overrideOf, .accessorOf]).isEmpty {
                    // ```
                    // class A { func f() {} }
                    // class B: A { override func f() {} }
                    // ```
                    // `B.f` is `overrideOf` `A.f`
                    // (B.f).relations has A.f
                    // B.f references A.f

                    let baseFunc = indexStore.getSymbol(for: rel.symbolRef)
                    guard let refKind = transformReferenceKind(baseFunc.kind, baseFunc.subKind) else {
                        logger.error("Failed to transform ref kind")
                        return false
                    }
                    let reference = Reference(kind: refKind, usr: baseFunc.usr, location: decl.location)
                    reference.name = baseFunc.name
                    if rel.roles.contains(.overrideOf) {
                        reference.isRelated = true
                    }
                    if self.referencedUsrsByDecl[decl] != nil {
                        self.referencedUsrsByDecl[decl]?.append(reference)
                    } else {
                        self.referencedUsrsByDecl[decl] = [reference]
                    }
                }

                if !rel.roles.intersection([.baseOf, .receivedBy, .calledBy, .extendedBy, .containedBy]).isEmpty {
                    // ```
                    // class A {}
                    // class B: A {}
                    // ```
                    // `A` is `baseOf` `B`
                    // A.relations has B as `baseOf`
                    // B referenes A
                    let referencer = indexStore.getSymbol(for: rel.symbolRef)
                    guard let refKind = transformReferenceKind(occ.symbol.kind, occ.symbol.subKind) else {
                        logger.error("Failed to transform ref kind")
                        return false
                    }
                    let reference = Reference(kind: refKind, usr: decl.usr, location: decl.location)
                    reference.name = decl.name
                    if rel.roles.contains(.baseOf) {
                        reference.isRelated = true
                    }
                    if self.referencedDeclsByUsr[referencer.usr] != nil {
                        self.referencedDeclsByUsr[referencer.usr]?.insert(reference)
                    } else {
                        self.referencedDeclsByUsr[referencer.usr] = [reference]
                    }
                }

                return true
            }
            return decl
        }

        private func _parseIndexedStructure(
            _ decl: Declaration,
            _ indexedStructure: [[String: Any]]
        ) throws {
            let matchingStructures = indexedStructure.lazy.filter {
                guard let structureKindName = $0[SourceKit.Key.kind.rawValue] as? String,
                    let structureKind = Declaration.Kind(rawValue: structureKindName) else { return false }

                var structureName = $0[SourceKit.Key.name.rawValue] as? String

                if let last = structureName?.split(separator: ".").last {
                    // Truncate e.g Notification.Name to just Name to match the index declaration.
                    structureName = String(last)
                }

                return decl.kind.isEqualToStructure(kind: structureKind) && structureName == decl.name
            }

            var substructures: [[String: Any]] = []
            for structure in matchingStructures {
                if let accessibilityName = structure[SourceKit.Key.accessibility.rawValue] as? String {
                    if let accessibility = Accessibility(rawValue: accessibilityName) {
                        decl.structureAccessibility = accessibility
                    } else {
                        throw PeripheryKitError.swiftIndexingError(message: "Unhandled accessibility '\(accessibilityName)'")
                    }
                }
                if let rawAttributes = structure[SourceKit.Key.attributes.rawValue] as? [[String: Any]] {
                    decl.attributes = parse(rawAttributes: rawAttributes)
                }
                substructures += structure[SourceKit.Key.substructure.rawValue] as? [[String: Any]] ?? []
            }
            for child in decl.declarations {
                try _parseIndexedStructure(child, substructures)
            }
        }

        private func _parseImplicit(_ occ: IndexStoreOccurrence) throws -> [Reference] {
            let loc = transformLocation(occ.location)

            var refs = [Reference]()

            indexStore.forEachRelations(for: occ) { rel -> Bool in
                if !rel.roles.intersection([.overrideOf]).isEmpty {
                    let baseFunc = indexStore.getSymbol(for: rel.symbolRef)
                    guard let refKind = transformReferenceKind(baseFunc.kind, baseFunc.subKind) else {
                        logger.error("Failed to transform ref kind")
                        return false
                    }
                    let reference = Reference(kind: refKind, usr: baseFunc.usr, location: loc)
                    reference.name = baseFunc.name
                    if rel.roles.contains(.overrideOf) {
                        reference.isRelated = true
                    }
                    if self.referencedDeclsByUsr[occ.symbol.usr] != nil {
                        self.referencedDeclsByUsr[occ.symbol.usr]?.insert(reference)
                    } else {
                        self.referencedDeclsByUsr[occ.symbol.usr] = [reference]
                    }
                    refs.append(reference)
                }
                return true
            }

            return refs
        }

        private func _parseReference(_ occ: IndexStoreOccurrence) throws -> [Reference] {
            guard let kind = transformReferenceKind(occ.symbol.kind, occ.symbol.subKind) else {
                throw PeripheryKitError.swiftIndexingError(message: "Failed to transform IndexStore kind into SourceKit kind: \(occ.symbol)")
            }
            let loc = transformLocation(occ.location)

            var refs = [Reference]()

            indexStore.forEachRelations(for: occ) { rel -> Bool in
                if !rel.roles.intersection([.baseOf, .receivedBy, .calledBy, .containedBy, .extendedBy]).isEmpty {
                    // ```
                    // class A {}
                    // class B: A {}
                    // ```
                    // `A` is `baseOf` `B`
                    // A.relations has B as `baseOf`
                    // B referenes A
                    let ref = Reference(kind: kind, usr: occ.symbol.usr, location: loc)
                    ref.name = occ.symbol.name
                    if rel.roles.contains(.baseOf) {
                        ref.isRelated = true
                    }
                    refs.append(ref)
                    let referencer = indexStore.getSymbol(for: rel.symbolRef)
                    if self.referencedDeclsByUsr[referencer.usr] != nil {
                        self.referencedDeclsByUsr[referencer.usr]?.insert(ref)
                    } else {
                        self.referencedDeclsByUsr[referencer.usr] = [ref]
                    }
                }
                return true
            }

            if refs.isEmpty {
                let ref = Reference(kind: kind, usr: occ.symbol.usr, location: loc)
                ref.name = occ.symbol.name
                refs.append(ref)
            }

            return refs
        }

        private func transformLocation(_ input: IndexStoreOccurrence.Location) -> SourceLocation {
            let file = SourceFile(path: Path(input.path))
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
            case .namespace, .namespacealias:
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
            case .enumconstant: return .enumelement
            case .instancemethod: return .functionMethodInstance
            case .classmethod: return .functionMethodClass
            case .staticmethod: return .functionMethodStatic
            case .instanceproperty: return .varInstance
            case .classproperty: return .varClass
            case .staticproperty: return .varStatic
            case .constructor: return .functionConstructor
            case .destructor: return .functionDestructor
            case .conversionfunction:
                logger.warn("'conversionfunction' is not supported on Swift")
                return nil
            case .parameter: return .varParameter
            case .using:
                logger.warn("'using' is not supported on Swift")
                return nil
            case .commenttag:
                logger.warn("'commenttag' is not supported on Swift")
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
                logger.warn("Skip to transform swiftAccessorRead")
            case .none: break
            case .cxxCopyConstructor, .cxxMoveConstructor,
                 .usingTypeName, .usingValue: break
            }

            switch kind {
            case .unknown: return nil
            case .module: return .module
            case .namespace, .namespacealias:
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
            case .enumconstant: return .enumelement
            case .instancemethod: return .functionMethodInstance
            case .classmethod: return .functionMethodClass
            case .staticmethod: return .functionMethodStatic
            case .instanceproperty: return .varInstance
            case .classproperty: return .varClass
            case .staticproperty: return .varStatic
            case .constructor: return .functionConstructor
            case .destructor: return .functionDestructor
            case .conversionfunction:
                logger.warn("'conversionfunction' is not supported on Swift")
                return nil
            case .parameter: return .varParameter
            case .using:
                logger.warn("'using' is not supported on Swift")
                return nil
            case .commenttag:
                logger.warn("'commenttag' is not supported on Swift")
                return nil
            }
        }

        private func parse(rawAttributes: [[String: Any]]) -> Set<String> {
            let attributes: [String] = rawAttributes.compactMap { rawAttribute in
                if let attributeName = rawAttribute[SourceKit.Key.attribute.rawValue] as? String {
                    let prefix = "source.decl.attribute."

                    if attributeName.hasPrefix(prefix) {
                        return String(attributeName.dropFirst(prefix.count))
                    }
                }

                return nil
            }

            return Set(attributes)
        }
    }
}
