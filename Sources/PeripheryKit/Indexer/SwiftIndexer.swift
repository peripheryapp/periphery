import Foundation
import PathKit
import SwiftSyntax
import SwiftIndexStore
import Shared

public final class SwiftIndexer {
    public static func make(storePath: String, sourceFiles: Set<Path>, graph: SourceGraph) throws -> Self {
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

    public func perform() throws {
        let excludedPaths = configuration.indexExcludeSourceFiles
        var unitsByFile: [Path: [IndexStoreUnit]] = [:]

        try indexStore.forEachUnits(includeSystem: false) { unit -> Bool in
            guard let filePath = try indexStore.mainFilePath(for: unit) else { return true }

            let file = Path(filePath)

            guard !excludedPaths.contains(file) else {
                self.logger.debug("[index:swift:exclude] \(file.string)")
                return true
            }

            if sourceFiles.contains(file) {
                unitsByFile[file, default: []].append(unit)
            }

            return true
        }

        let jobs = unitsByFile.map { (file, units) in
            Job(
                file: file,
                units: units,
                graph: graph,
                indexStore: indexStore,
                logger: logger
            )
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

        private let units: [IndexStoreUnit]
        private let graph: SourceGraph
        private let logger: Logger
        private let indexStore: IndexStore

        required init(
            file: Path,
            units: [IndexStoreUnit],
            graph: SourceGraph,
            indexStore: IndexStore,
            logger: Logger
        ) {
            self.file = file
            self.units = units
            self.graph = graph
            self.logger = logger
            self.indexStore = indexStore
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
                let location: SourceLocation
            }

            let usr: String
            let kind: Declaration.Kind
            let name: String?
            let isImplicit: Bool
            let location: SourceLocation

            var key: Key {
                Key(kind: kind, name: name, isImplicit: isImplicit, location: location)
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

                if decl.isImplicit {
                    graph.markRetained(decl)
                }

                let relations = values.flatMap { $0.1 }
                try parseDeclaration(decl, relations)

                graph.add(decl)
                decls.append(decl)
            }

            establishDeclarationHierarchy()
            associateDanglingReferences(with: decls)

            let syntax = try SyntaxParser.parse(file.url)
            let locationConverter = SourceLocationConverter(file: file.string, tree: syntax)
            let result = try identifyMetadata(for: decls, syntax: syntax, locationConverter: locationConverter)
            try identifyUnusedParameters(for: decls.filter { $0.kind.isFunctionKind }, syntax: syntax, locationConverter: locationConverter)
            applyCommands(for: decls, metadataResult: result)
        }

        private var childDeclsByParentUsr: [String: Set<Declaration>] = [:]
        private var referencedDeclsByUsr: [String: Set<Reference>] = [:]
        private var referencedUsrsByDecl: [Declaration: [Reference]] = [:]
        private var danglingReferences: [Reference] = []
        private var varParameterUsrs: Set<String> = []

        private func establishDeclarationHierarchy() {
            for (parent, decls) in childDeclsByParentUsr {
                guard let parentDecl = graph.explicitDeclaration(withUsr: parent) else {
                    if varParameterUsrs.contains(parent) {
                        // These declarations are children of a parameter and are redundant.
                        decls.forEach { graph.remove($0) }
                    }

                    continue
                }

                graph.mutating {
                    for decl in decls {
                        decl.parent = parentDecl
                    }

                    parentDecl.declarations.formUnion(decls)
                }
            }

            for (usr, references) in referencedDeclsByUsr {
                guard let decl = graph.explicitDeclaration(withUsr: usr) else {
                    danglingReferences.append(contentsOf: references)
                    continue
                }

                graph.mutating {
                    for reference in references {
                        reference.parent = decl

                        if reference.isRelated {
                            decl.related.insert(reference)
                        } else {
                            decl.references.insert(reference)
                        }
                    }
                }
            }

            graph.mutating {
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

        private func applyCommands(for decls: [Declaration], metadataResult result: MetadataParser.Result) {
            if result.fileCommands.contains(.ignoreAll) {
                retainHierarchy(decls)
            } else {
                for decl in decls {
                    if decl.commentCommands.contains(.ignore) {
                        retainHierarchy([decl])
                    }
                }
            }
        }

        private func identifyMetadata(
            for decls: [Declaration],
            syntax: SourceFileSyntax,
            locationConverter: SourceLocationConverter
        ) throws -> MetadataParser.Result {
            let declsByLocation = decls.reduce(into: [SourceLocation: [Declaration]]()) { (result, decl) in
                result[decl.location, default: []].append(decl)
            }

            let result = try MetadataParser.parse(
                file: file,
                syntax: syntax,
                locationConverter: locationConverter)

            for metadata in result.metadata {
                guard let decls = declsByLocation[metadata.location] else {
                    // The declaration may not exist if the code was not compiled due to build conditions, e.g #if.
                    logger.debug("[index:swift] Expected declaration at \(metadata.location)")
                    continue
                }

                for decl in decls {
                    if let accessibility = metadata.accessibility {
                        decl.accessibility = (accessibility, true)
                    }

                    decl.attributes = Set(metadata.attributes)
                    decl.modifiers = Set(metadata.modifiers)
                    decl.commentCommands = Set(metadata.commentCommands)
                }
            }

            return result
        }

        private func retainHierarchy(_ decls: [Declaration]) {
            decls.forEach {
                graph.markRetained($0)
                $0.unusedParameters.forEach { graph.markRetained($0) }
                retainHierarchy(Array($0.declarations))
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

                    if ignoredParamNames.contains(param.name) {
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
            let kind = try transformDeclarationKind(occurrence.symbol.kind, occurrence.symbol.subKind)

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

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = try? transformReferenceKind(baseFunc.kind, baseFunc.subKind) {
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

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = try? transformReferenceKind(baseFunc.kind, baseFunc.subKind) {
                        let reference = Reference(kind: baseFuncKind, usr: baseFuncUsr, location: location)
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
            let kind = try transformReferenceKind(occurrence.symbol.kind, occurrence.symbol.subKind)

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

            refs.forEach { graph.add($0) }
        }

        private func transformLocation(_ input: IndexStoreOccurrence.Location) -> SourceLocation? {
            return SourceLocation(file: file, line: input.line, column: input.column)
        }

        private func transformDeclarationKind(_ kind: IndexStoreSymbol.Kind, _ subKind: IndexStoreSymbol.SubKind) throws -> Declaration.Kind {
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
            default: break
            }

            throw PeripheryError.swiftIndexingError(message: "Failed to transform IndexStoreSymbol declaration kind: \(kind), subKind: \(subKind)")
        }

        private func transformReferenceKind(_ kind: IndexStoreSymbol.Kind, _ subKind: IndexStoreSymbol.SubKind) throws -> Reference.Kind {
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
            default: break
            }

            throw PeripheryError.swiftIndexingError(message: "Failed to transform IndexStoreSymbol reference kind: \(kind), subKind: \(subKind)")
        }
    }
}
