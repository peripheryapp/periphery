import Configuration
import Foundation
import IndexStore
import Logger
import Shared
import SourceGraph
import SyntaxAnalysis
import SystemPackage

public struct IndexUnit {
    let store: IndexStore
    let unit: UnitReader
}

final class SwiftIndexer: Indexer {
    private let sourceFiles: [SourceFile: [IndexUnit]]
    private let graph: SourceGraphMutex
    private let logger: ContextualLogger
    private let configuration: Configuration
    private let swiftVersion: SwiftVersion

    required init(
        sourceFiles: [SourceFile: [IndexUnit]],
        graph: SourceGraphMutex,
        logger: ContextualLogger,
        configuration: Configuration,
        swiftVersion: SwiftVersion
    ) {
        self.sourceFiles = sourceFiles
        self.graph = graph
        self.logger = logger.contextualized(with: "swift")
        self.configuration = configuration
        self.swiftVersion = swiftVersion
        super.init(configuration: configuration)
    }

    func perform() throws {
        let jobs = sourceFiles.map { file, units -> Job in
            Job(
                sourceFile: file,
                units: units,
                retainAllDeclarations: isRetained(file),
                graph: graph,
                logger: logger,
                configuration: configuration,
                swiftVersion: swiftVersion
            )
        }

        let phaseOneInterval = logger.beginInterval("index:swift:phase:one")

        try JobPool(jobs: jobs).forEach { job in
            if self.configuration.verbose {
                let phaseOneLogger = self.logger.contextualized(with: "phase:one")
                let elapsed = try Benchmark.measure { try job.phaseOne() }
                self.debug(logger: phaseOneLogger, sourceFile: job.sourceFile, elapsed: elapsed)
            } else {
                try job.phaseOne()
            }
        }

        logger.endInterval(phaseOneInterval)

        let phaseTwoInterval = logger.beginInterval("index:swift:phase:two")

        try JobPool(jobs: jobs).forEach { job in
            if self.configuration.verbose {
                let phaseTwoLogger = self.logger.contextualized(with: "phase:two")
                let elapsed = try Benchmark.measure { try job.phaseTwo() }
                self.debug(logger: phaseTwoLogger, sourceFile: job.sourceFile, elapsed: elapsed)
            } else {
                try job.phaseTwo()
            }
        }

        logger.endInterval(phaseTwoInterval)
    }

    // MARK: - Private

    private func debug(logger: ContextualLogger, sourceFile: SourceFile, elapsed: String) {
        guard configuration.verbose else { return }

        let modules = sourceFile.modules.joined(separator: ", ")
        logger.debug("\(sourceFile.path.string) (\(modules)) (\(elapsed)s)")
    }

    private final class Job {
        let sourceFile: SourceFile

        private let units: [IndexUnit]
        private let graph: SourceGraphMutex
        private let logger: ContextualLogger
        private let configuration: Configuration
        private var retainAllDeclarations: Bool
        private let swiftVersion: SwiftVersion

        required init(
            sourceFile: SourceFile,
            units: [IndexUnit],
            retainAllDeclarations: Bool,
            graph: SourceGraphMutex,
            logger: ContextualLogger,
            configuration: Configuration,
            swiftVersion: SwiftVersion
        ) {
            self.sourceFile = sourceFile
            self.units = units
            self.retainAllDeclarations = retainAllDeclarations
            self.graph = graph
            self.logger = logger
            self.configuration = configuration
            self.swiftVersion = swiftVersion
        }

        // swiftlint:disable nesting
        struct RawRelation {
            struct Symbol {
                let name: String
                let usr: String?
                let kind: SymbolKind
                let subKind: SymbolSubkind
            }

            let symbol: Symbol
            let roles: SymbolRoles
        }

        struct RawDeclaration {
            struct Key: Hashable {
                let kind: Declaration.Kind
                let name: String
                let isImplicit: Bool
                let isObjcAccessible: Bool
                let location: Location
            }

            let usr: String
            let kind: Declaration.Kind
            let name: String
            let isImplicit: Bool
            let isObjcAccessible: Bool
            let location: Location

            var key: Key {
                Key(kind: kind, name: name, isImplicit: isImplicit, isObjcAccessible: isObjcAccessible, location: location)
            }
        }

        // swiftlint:enable nesting

        /// Phase one reads the index store and establishes the declaration hierarchy and the majority of references.
        /// Some references may depend upon declarations in other files, and thus their association is deferred until
        /// phase two.
        func phaseOne() throws {
            var rawDeclsByKey: [RawDeclaration.Key: [(RawDeclaration, [RawRelation])]] = [:]
            var references: Set<Reference> = []

            for unit in units {
                for recordName in unit.unit.recordNames {
                    let record = try RecordReader(indexStore: unit.store, recordName: recordName)

                    record.forEach(occurrence: { occurrence in
                        let usr = occurrence.symbol.usr
                        guard let location = self.transformLocation(occurrence.location)
                        else { return }

                        var relations: [RawRelation] = []
                        occurrence.forEach(relation: { relSymbol, relRoles in
                            relations.append(RawRelation(
                                symbol: .init(
                                    name: relSymbol.name,
                                    usr: relSymbol.usr,
                                    kind: relSymbol.kind,
                                    subKind: relSymbol.subkind
                                ),
                                roles: relRoles
                            ))
                        })

                        if !occurrence.roles.isDisjoint(with: [.definition, .declaration]) {
                            if let (decl, relations) = self.parseRawDeclaration(
                                occurrence,
                                usr,
                                location,
                                relations
                            ) {
                                rawDeclsByKey[decl.key, default: []].append((decl, relations))
                            }
                        }

                        if occurrence.roles.contains(.reference) {
                            references.formUnion(self.parseReference(
                                occurrence,
                                usr,
                                location,
                                relations
                            ))
                        }

                        if occurrence.roles.contains(.implicit) {
                            references.formUnion(self.parseImplicit(
                                usr,
                                location,
                                relations
                            ))
                        }
                    })
                }
            }

            var newDeclarations: Set<Declaration> = []

            for (key, values) in rawDeclsByKey {
                let usrs = values.mapSet { $0.0.usr }
                let decl = Declaration(name: key.name, kind: key.kind, usrs: usrs, location: key.location)

                decl.isImplicit = key.isImplicit
                decl.isObjcAccessible = key.isObjcAccessible

                if decl.isImplicit {
                    graph.withLock { $0.markRetained(decl) }
                }

                if decl.isObjcAccessible, configuration.retainObjcAccessible {
                    graph.withLock { $0.markRetained(decl) }
                }

                let relations = values.flatMap(\.1)
                references.formUnion(parseDeclaration(decl, relations))

                newDeclarations.insert(decl)
                declarations.append(decl)
            }

            graph.withLock { graph in
                graph.add(references)
                graph.add(newDeclarations)

                if retainAllDeclarations {
                    graph.markRetained(newDeclarations)
                }
            }

            establishDeclarationHierarchy()
        }

        /// Phase two associates latent references, and performs other actions that depend on the completed source graph.
        func phaseTwo() throws {
            if !configuration.disableUnusedImportAnalysis {
                graph.withLock { graph in
                    graph.addIndexedSourceFile(sourceFile)
                    graph.addIndexedModules(sourceFile.modules)
                }
            }

            let multiplexingSyntaxVisitor = try MultiplexingSyntaxVisitor(file: sourceFile, swiftVersion: swiftVersion)
            let declarationSyntaxVisitor = multiplexingSyntaxVisitor.add(DeclarationSyntaxVisitor.self)
            let importSyntaxVisitor = multiplexingSyntaxVisitor.add(ImportSyntaxVisitor.self)

            multiplexingSyntaxVisitor.visit()

            sourceFile.importStatements = importSyntaxVisitor.importStatements
            sourceFile.importsSwiftTesting = importSyntaxVisitor.importStatements.contains(where: { $0.module == "Testing" })

            if !configuration.disableUnusedImportAnalysis {
                for stmt in sourceFile.importStatements where stmt.isExported {
                    graph.withLock { graph in
                        graph.addExportedModule(stmt.module, exportedBy: sourceFile.modules)
                    }
                }
            }

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
        private var extensionUsrMap: [String: String] = [:]

        private func establishDeclarationHierarchy() {
            graph.withLock { graph in
                for (parent, decls) in childDeclsByParentUsr {
                    guard let parentDecl = graph.declaration(withUsr: parent) else {
                        if varParameterUsrs.contains(parent) {
                            // These declarations are children of a parameter and are redundant.
                            decls.forEach { graph.remove($0) }
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
                graph.withLock { graph in
                    if let decl = graph.declaration(withUsr: usr) {
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

            // Sort declarations to ensure deterministic candidate selection when
            // multiple declarations exist at the same location.
            let sortedDeclarations = declarations.sorted()

            let declsByLocation = sortedDeclarations
                .reduce(into: [Location: [Declaration]]()) { result, decl in
                    result[decl.location, default: []].append(decl)
                }
            let declsByLine = sortedDeclarations
                .reduce(into: [Int: [Declaration]]()) { result, decl in
                    result[decl.location.line, default: []].append(decl)
                }
            let sortedDeclLines = declsByLine.keys.sorted().reversed()

            for ref in danglingReferences {
                let sameLineCandidateDecls = declsByLocation[ref.location] ??
                    declsByLine[ref.location.line]
                var candidateDecls = [Declaration]()

                if let sameLineCandidateDecls {
                    candidateDecls = sameLineCandidateDecls
                } else {
                    // For references with no declaration on the same line, find the nearest preceding declaration.
                    if let line = sortedDeclLines.first(where: { $0 < ref.location.line }) {
                        candidateDecls = declsByLine[line]?.filter {
                            !$0.usrs.contains(ref.usr) &&
                                !$0.ancestralDeclarations.contains(where: { $0.usrs.contains(ref.usr) })
                        } ?? []
                    }
                }

                // The vast majority of the time there will only be a single declaration for this location,
                // however it is possible for there to be more than one. In that case, first attempt to associate with
                // a decl without a parent, as the reference may be a related type of a class/struct/etc.
                if let decl = candidateDecls.first(where: { $0.parent == nil }) {
                    associate(ref, with: decl)
                } else if let decl = candidateDecls.min() {
                    // Fallback to using the first declaration.
                    // Sorting the declarations helps in the situation where the candidate declarations includes a
                    // property/subscript, and a getter on the same line. The property/subscript is more likely to be
                    // the declaration that should hold the references.
                    associate(ref, with: decl)
                }
            }
        }

        private func applyCommentCommands(using syntaxVisitor: MultiplexingSyntaxVisitor) {
            let fileCommands = syntaxVisitor.parseComments()

            if fileCommands.contains(.ignoreAll) {
                commandIgnore(declarations, kind: .file)
            } else {
                for decl in declarations where decl.commentCommands.contains(.ignore) {
                    commandIgnore([decl], kind: .declaration)
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
            graph.withLock { _ in
                if let accessibility = result.accessibility {
                    decl.accessibility = .init(value: accessibility, isExplicit: true)
                }

                decl.attributes = Set(result.attributes)
                decl.modifiers = Set(result.modifiers)
                decl.commentCommands = Set(result.commentCommands)
                decl.declaredType = result.variableType

                decl.hasGenericFunctionReturnedMetatypeParameters = result.hasGenericFunctionReturnedMetatypeParameters

                for ref in decl.references.union(decl.related) {
                    if result.inheritedTypeLocations.contains(ref.location) {
                        if decl.kind.isConformableKind, ref.declarationKind == .protocol {
                            ref.role = .conformedType
                        } else if decl.kind == .protocol, ref.declarationKind == .protocol {
                            ref.role = .refinedProtocolType
                        } else if decl.kind == .class || decl.kind == .associatedtype {
                            ref.role = .inheritedType
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
                    } else if result.typeInitializerLocations.contains(ref.location) {
                        ref.role = .initializerType
                    } else if result.variableInitExprLocations.contains(ref.location) {
                        ref.role = .initializerType
                    }
                }
            }
        }

        private func commandIgnore(_ decls: [Declaration], kind: CommandIgnoreKind) {
            for decl in decls {
                graph.withLock { graph in
                    graph.markRetained(decl)
                    decl.unusedParameters.forEach { graph.markRetained($0) }

                    graph.markCommandIgnored(decl, kind: kind)
                    decl.unusedParameters.forEach { graph.markCommandIgnored($0, kind: kind) }
                }
                commandIgnore(Array(decl.declarations), kind: kind)
            }
        }

        private func associate(_ ref: Reference, with decl: Declaration) {
            graph.withLock { _ in
                associateUnsafe(ref, with: decl)
            }
        }

        private func associateUnsafe(_ ref: Reference, with decl: Declaration) {
            ref.parent = decl

            if ref.kind == .related {
                decl.related.insert(ref)
            } else {
                decl.references.insert(ref)
            }
        }

        private func identifyUnusedParameters(using syntaxVisitor: MultiplexingSyntaxVisitor) {
            let functionDecls = declarations.filter(\.kind.isFunctionKind)
            let functionDeclsByLocation = functionDecls.reduce(into: [Location: Declaration]()) {
                $0[$1.location] = $1
            }

            // Build a map of ignored param names per function, and track functions with ignored
            // params so ScanResultBuilder can efficiently detect superfluous ignores.
            var ignoredParamsByLocation: [Location: [String]] = [:]
            for functionDecl in functionDecls {
                let ignoredParamNames = functionDecl.commentCommands.ignoredParameterNames
                if !ignoredParamNames.isEmpty {
                    ignoredParamsByLocation[functionDecl.location] = ignoredParamNames
                    graph.withLock { $0.markHasIgnoredParameters(functionDecl) }
                }
            }

            let analyzer = UnusedParameterAnalyzer()
            let paramsByFunction = analyzer.analyze(
                file: syntaxVisitor.sourceFile,
                syntax: syntaxVisitor.syntax,
                locationConverter: syntaxVisitor.locationConverter,
                parseProtocols: true
            )

            for (function, params) in paramsByFunction {
                guard let functionDecl = functionDeclsByLocation[function.location] else {
                    // The declaration may not exist if the code was not compiled due to build conditions, e.g #if.
                    logger.debug("Failed to associate indexed function for parameter function '\(function.name)' at \(function.location).")
                    continue
                }

                let ignoredParamNames = ignoredParamsByLocation[functionDecl.location] ?? []

                graph.withLock { graph in
                    for param in params {
                        let paramDecl = param.makeDeclaration(withParent: functionDecl)
                        functionDecl.unusedParameters.insert(paramDecl)
                        graph.add(paramDecl)

                        if retainAllDeclarations || (functionDecl.isObjcAccessible && configuration.retainObjcAccessible) {
                            graph.markRetained(paramDecl)
                        } else if ignoredParamNames.contains(param.name.text) {
                            graph.markRetained(paramDecl)
                            graph.markCommandIgnored(paramDecl, kind: .declaration)
                        }
                    }
                }
            }
        }

        private func parseRawDeclaration(
            _ occurrence: SymbolOccurrence,
            _ usr: String,
            _ location: Location,
            _ relations: [RawRelation]
        ) -> (RawDeclaration, [RawRelation])? {
            guard let kind = transformDeclarationKind(occurrence.symbol.kind, occurrence.symbol.subkind)
            else { return nil }
            guard kind != .varParameter else {
                // Ignore indexed parameters as unused parameter identification is performed separately using SwiftSyntax.
                // Record the USR so that we can also ignore implicit accessor declarations.
                varParameterUsrs.insert(usr)
                return nil
            }

            var usr = usr

            if kind.isExtensionKind {
                // Identical extensions in different modules have the same USR, which leads to conflicts and incorrect
                // results. Here we append the module names to form a unique USR. The only references to this
                // extension will exist in the same file, so we only need a file-local mapping for the USR.
                let newUsr = "\(usr)-\(location.file.modules.sorted().joined(separator: "-"))"
                extensionUsrMap[usr] = newUsr
                usr = newUsr
            }

            let decl = RawDeclaration(
                usr: usr,
                kind: kind,
                name: occurrence.symbol.name,
                isImplicit: occurrence.roles.contains(.implicit),
                isObjcAccessible: usr.hasPrefix("c:"),
                location: location
            )

            return (decl, relations)
        }

        private func parseDeclaration(
            _ decl: Declaration,
            _ relations: [RawRelation]
        ) -> Set<Reference> {
            var references: Set<Reference> = []

            for rel in relations {
                if rel.roles.contains(.childOf) {
                    if let parentUsr = rel.symbol.usr {
                        var parentUsr = parentUsr
                        if rel.symbol.kind == .extension {
                            parentUsr = extensionUsrMap[parentUsr] ?? parentUsr
                        }
                        childDeclsByParentUsr[parentUsr, default: []].insert(decl)
                    }
                }

                if rel.roles.contains(.overrideOf) {
                    let baseFunc = rel.symbol

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = transformDeclarationKind(baseFunc.kind, baseFunc.subKind) {
                        let reference = Reference(
                            name: baseFunc.name,
                            kind: .related,
                            declarationKind: baseFuncKind,
                            usr: baseFuncUsr,
                            location: decl.location
                        )
                        reference.parent = decl
                        decl.related.insert(reference)
                        references.insert(reference)
                    }
                }

                if !rel.roles.isDisjoint(with: [.baseOf, .calledBy, .extendedBy, .containedBy]) {
                    let referencer = rel.symbol

                    if let referencerUsr = referencer.usr {
                        for usr in decl.usrs {
                            let reference = Reference(
                                name: decl.name,
                                kind: rel.roles.contains(.baseOf) ? .related : .normal,
                                declarationKind: decl.kind,
                                usr: usr,
                                location: decl.location
                            )
                            references.insert(reference)
                            referencesByUsr[referencerUsr, default: []].insert(reference)
                        }
                    }
                }
            }

            return references
        }

        private func parseImplicit(
            _ occurrenceUsr: String,
            _ location: Location,
            _ relations: [RawRelation]
        ) -> [Reference] {
            var refs = [Reference]()

            for relation in relations {
                if relation.roles.contains(.overrideOf) {
                    let baseFunc = relation.symbol

                    if let baseFuncUsr = baseFunc.usr, let baseFuncKind = transformDeclarationKind(baseFunc.kind, baseFunc.subKind) {
                        let reference = Reference(
                            name: baseFunc.name,
                            kind: .related,
                            declarationKind: baseFuncKind,
                            usr: baseFuncUsr,
                            location: location
                        )
                        referencesByUsr[occurrenceUsr, default: []].insert(reference)
                        refs.append(reference)
                    }
                }
            }

            return refs
        }

        private func parseReference(
            _ occurrence: SymbolOccurrence,
            _ occurrenceUsr: String,
            _ location: Location,
            _ relations: [RawRelation]
        ) -> [Reference] {
            guard let kind = transformDeclarationKind(occurrence.symbol.kind, occurrence.symbol.subkind)
            else { return [] }
            guard kind != .varParameter else {
                // Ignore indexed parameters as unused parameter identification is performed separately using SwiftSyntax.
                return []
            }

            var refs = [Reference]()

            for relation in relations {
                if !relation.roles.isDisjoint(with: [.baseOf, .calledBy, .containedBy, .extendedBy]) {
                    let referencer = relation.symbol

                    if let referencerUsr = referencer.usr {
                        let ref = Reference(
                            name: occurrence.symbol.name,
                            kind: relation.roles.contains(.baseOf) ? .related : .normal,
                            declarationKind: kind,
                            usr: occurrenceUsr,
                            location: location
                        )
                        refs.append(ref)
                        referencesByUsr[referencerUsr, default: []].insert(ref)
                    }
                }
            }

            if refs.isEmpty {
                let ref = Reference(
                    name: occurrence.symbol.name,
                    kind: .normal,
                    declarationKind: kind,
                    usr: occurrenceUsr,
                    location: location
                )
                refs.append(ref)

                // The index store doesn't contain any relations for this reference, save it so that we can attempt
                // to associate it with the correct declaration later based on location.
                if ref.declarationKind != .module {
                    danglingReferences.append(ref)
                }
            }

            return refs
        }

        private func transformLocation(_ input: (line: Int, column: Int)) -> Location? {
            Location(file: sourceFile, line: input.line, column: input.column)
        }

        private func transformDeclarationKind(_ kind: SymbolKind, _ subKind: SymbolSubkind) -> Declaration.Kind? {
            switch subKind {
            case .accessorGetter: return .functionAccessorGetter
            case .accessorSetter: return .functionAccessorSetter
            case .swiftAccessorDidSet: return .functionAccessorDidset
            case .swiftAccessorWillSet: return .functionAccessorWillset
            case .swiftAccessorMutableAddressor: return .functionAccessorMutableaddress
            case .swiftAccessorAddressor: return .functionAccessorAddress
            case .swiftAccessorRead: return .functionAccessorRead
            case .swiftAccessorModify: return .functionAccessorModify
            case .swiftAccessorInit: return .functionAccessorInit
            case .swiftSubscript: return .functionSubscript
            case .swiftInfixOperator: return .functionOperatorInfix
            case .swiftPrefixOperator: return .functionOperatorPrefix
            case .swiftPostfixOperator: return .functionOperatorPostfix
            case .swiftGenericParameter: return .genericTypeParam
            case .swiftAssociatedType: return .associatedtype
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
            case .macro: return .macro
            default: return nil
            }
        }
    }
}
