import Foundation
import PathKit
import SwiftSyntax
import SwiftIndexStore

final class IndexStoreIndexer: TypeIndexer {
    static func make(buildPlan: BuildPlan, graph: SourceGraph, project: XcodeProjectlike) throws -> Self {
        let xcodebuild = inject(Xcodebuild.self)
        let storePath: String

        if let env = ProcessInfo.processInfo.environment["BUILD_ROOT"] {
            storePath = (Path(env).absolute().parent().parent() + "Index/DataStore").string
        } else {
            storePath = try xcodebuild.indexStorePath(project: project)
        }

        let storeURL = URL(fileURLWithPath: storePath)

        return self.init(buildPlan: buildPlan,
                         graph: graph,
                         indexStore: try IndexStore.open(store: storeURL, lib: .open()),
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

        let allowedSourceFilesPaths = Set(try buildPlan.targets.map { try $0.sourceFiles().map { $0.path } }.joined())
        let excludedPaths = configuration.indexExcludeSourceFiles.map { $0.path }

        try indexStore.forEachUnits(includeSystem: false) { unit -> Bool in
            guard let filePath = try indexStore.mainFilePath(for: unit) else { return true }

            let path = Path(filePath)

            guard !excludedPaths.contains(path) else {
                self.logger.debug("[index:swift:exclude] \(path.string)")
                return true
            }

            if allowedSourceFilesPaths.contains(path) {
                jobs.append(
                    Job(
                        filePath: path,
                        unit: unit,
                        buildPlan: buildPlan,
                        graph: graph,
                        indexStore: indexStore,
                        logger: logger,
                        featureManager: featureManager,
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

            self.logger.debug("[index:swift] \(job.filePath) (\(elapsed)s)")
        }

        graph.identifyRootDeclarations()
        graph.identifyRootReferences()
    }

    // MARK: - Private

    private class Job {
        let filePath: Path

        private let unit: IndexStoreUnit
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

        required init(
            filePath: Path,
            unit: IndexStoreUnit,
            buildPlan: BuildPlan,
            graph: SourceGraph,
            indexStore: IndexStore,
            logger: Logger,
            featureManager: FeatureManager,
            configuration: Configuration
        ) {
            self.filePath = filePath
            self.unit = unit
            self.buildPlan = buildPlan
            self.graph = graph
            self.logger = logger
            self.featureManager = featureManager
            self.configuration = configuration
            self.indexStore = indexStore
        }

        func perform() throws {
            var decls: [Declaration] = []

            try indexStore.forEachRecordDependencies(for: unit) { dependency in
                guard case let .record(record) = dependency else { return true }

                try indexStore.forEachOccurrences(for: record) { occurrence in
                    guard let usr = occurrence.symbol.usr,
                          let location = transformLocation(occurrence.location),
                          occurrence.symbol.language == .swift else { return true }

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
            try determineAccessibilityFromStructure(for: decls)
            try identifyUnusedParameters(for: decls.filter { $0.kind.isFunctionKind })
        }

        private var childDeclsByParentUsr: [String: Set<Declaration>] = [:]
        private var referencedDeclsByUsr: [String: Set<Reference>] = [:]
        private var referencedUsrsByDecl: [Declaration: [Reference]] = [:]
        private var danglingReferences: [Reference] = []

        private func establishDeclarationHierarchy() {
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

        // Workaround for https://bugs.swift.org/browse/SR-13766
        private func associateDanglingReferences(with decls: [Declaration]) {
            guard !danglingReferences.isEmpty else { return }

            let declsByLocation = decls.lazy.map { ($0.location, $0) }.reduce(into: [SourceLocation: [Declaration]]()) { (result, tuple) in
                result[tuple.0, default: []].append(tuple.1)
            }
            let declsByLine = decls.lazy.map { ($0.location.line, $0) }.reduce(into: [Int64: [Declaration]]()) { (result, tuple) in
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

        private func identifyUnusedParameters(for decls: [Declaration]) throws {
            let functionDelcsByLocation = decls.filter { $0.kind.isFunctionKind }.map { ($0.location, $0) }.reduce(into: [SourceLocation: Declaration]()) { $0[$1.0] = $1.1 }

            let analyzer = UnusedParameterAnalyzer()
            let params = try analyzer.analyze(file: filePath, parseProtocols: true)

            for param in params {
                guard let paramFunction = param.function else { continue }

                guard let functionDecl = functionDelcsByLocation[paramFunction.location] else {
                    fatalError("Failed to associate indexed function for parameter function '\(paramFunction.name)' at \(paramFunction.location)")
                }

                let paramDecl = param.declaration
                paramDecl.parent = functionDecl
                functionDecl.unusedParameters.insert(paramDecl)
                graph.add(paramDecl)
            }
        }

        private func parseDeclaration(
            _ occurrence: IndexStoreOccurrence,
            _ occurrenceUsr: String,
            _ location: SourceLocation
        ) throws -> Declaration? {
            guard let kind = transformDeclarationKind(occurrence.symbol.kind, occurrence.symbol.subKind) else {
                throw PeripheryKitError.swiftIndexingError(message: "Failed to transform IndexStore kind into SourceKit kind: \(occurrence.symbol)")
            }

            guard kind != .varParameter else {
                // Ignore indexed parameters as unused parameter identification is performed separately using SwiftSyntax.
                return nil
            }

            let decl = Declaration(kind: kind, usr: occurrenceUsr, location: location)
            decl.name = occurrence.symbol.name

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if !rel.roles.intersection([.childOf]).isEmpty {
                    if let parentUsr = rel.symbol.usr {
                        if self.childDeclsByParentUsr[parentUsr] != nil {
                            self.childDeclsByParentUsr[parentUsr]?.insert(decl)
                        } else {
                            self.childDeclsByParentUsr[parentUsr] = [decl]
                        }
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

                        if self.referencedUsrsByDecl[decl] != nil {
                            self.referencedUsrsByDecl[decl]?.append(reference)
                        } else {
                            self.referencedUsrsByDecl[decl] = [reference]
                        }
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

                        if self.referencedDeclsByUsr[referencerUsr] != nil {
                            self.referencedDeclsByUsr[referencerUsr]?.insert(reference)
                        } else {
                            self.referencedDeclsByUsr[referencerUsr] = [reference]
                        }
                    }
                }

                return true
            }

            graph.add(decl)
            return decl
        }

        private func determineAccessibilityFromStructure(for decls: [Declaration]) throws {
            let file = SourceFile(path: filePath)
            let structure = try self.indexStructure.get(file)

            for decl in decls {
                guard decl.parent == nil else { continue }
                try determineAccessibilityFromStructure(for: decl, with: structure)
            }
        }

        private func determineAccessibilityFromStructure(for decl: Declaration, with structure: [[String: Any]]) throws {
            let matchingStructures = structure.lazy.filter {
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
                try determineAccessibilityFromStructure(for: child, with: substructures)
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

                    if let baseFuncUsr = baseFunc.usr {
                        guard let refKind = transformReferenceKind(baseFunc.kind, baseFunc.subKind) else {
                            logger.error("Failed to transform ref kind")
                            return false
                        }

                        let reference = Reference(kind: refKind, usr: baseFuncUsr, location: location)
                        reference.name = baseFunc.name
                        reference.isRelated = true

                        graph.add(reference)

                        if self.referencedDeclsByUsr[occurrenceUsr] != nil {
                            self.referencedDeclsByUsr[occurrenceUsr]?.insert(reference)
                        } else {
                            self.referencedDeclsByUsr[occurrenceUsr] = [reference]
                        }

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
                throw PeripheryKitError.swiftIndexingError(message: "Failed to transform IndexStore kind into SourceKit kind: \(occurrence.symbol)")
            }

            var refs = [Reference]()

            indexStore.forEachRelations(for: occurrence) { rel -> Bool in
                if !rel.roles.intersection([.baseOf, .receivedBy, .calledBy, .containedBy, .extendedBy]).isEmpty {
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

                        if self.referencedDeclsByUsr[referencerUsr] != nil {
                            self.referencedDeclsByUsr[referencerUsr]?.insert(ref)
                        } else {
                            self.referencedDeclsByUsr[referencerUsr] = [ref]
                        }
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
            guard let path = input.path else { return nil }

            let file = SourceFile(path: Path(path))
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
