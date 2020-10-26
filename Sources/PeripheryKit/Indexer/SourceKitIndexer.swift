import Foundation
import PathKit
import SwiftSyntax

final class SourceKitIndexer: TypeIndexer {
    static func make(buildPlan: XcodeBuildPlan, graph: SourceGraph, project: XcodeProjectlike) -> Self {
        return self.init(buildPlan: buildPlan,
                         graph: graph,
                         logger: inject(),
                         featureManager: inject(),
                         configuration: inject())
    }

    private let buildPlan: XcodeBuildPlan
    private let graph: SourceGraph
    private let logger: Logger
    private let featureManager: FeatureManager
    private let configuration: Configuration

    private typealias Job = (sourceFile: SourceFile, sourceKit: SourceKit)

    required init(buildPlan: XcodeBuildPlan,
                  graph: SourceGraph,
                  logger: Logger,
                  featureManager: FeatureManager,
                  configuration: Configuration) {
        self.buildPlan = buildPlan
        self.graph = graph
        self.logger = logger
        self.featureManager = featureManager
        self.configuration = configuration
    }

    func perform() throws {
        var jobs: [Job] = []
        let excludedSourceFiles = configuration.indexExcludeSourceFiles

        for target in buildPlan.targets {
            let sourceKit = try SourceKit.make(buildPlan: buildPlan, target: target)
            let sourceFiles = try target.sourceFiles()
            jobs.append(contentsOf: sourceFiles.map { Job($0, sourceKit) })
        }

        try JobPool<Void>().forEach(jobs) { [weak self] job in
            guard let self = self else { return }

            let sourceFile = job.sourceFile

            if excludedSourceFiles.contains(sourceFile) {
                self.logger.debug("[index:swift:exclude] \(sourceFile.path.string)")
                return
            }

            let sourceKit = job.sourceKit

            let elapsed = try Benchmark.measure {
                try self.parseIndex(sourceFile, sourceKit)
                try self.parseUnusedParams(sourceFile, sourceKit)
            }

            self.logger.debug("[index:swift] \(sourceFile.path.string) (\(elapsed)s)")
        }

        graph.identifyRootDeclarations()
        graph.identifyRootReferences()
    }

    // MARK: - Private

    private func parseIndex(_ sourceFile: SourceFile, _ sourceKit: SourceKit) throws {
        let index = try sourceKit.requestIndex(sourceFile)
        var rawStructures: [[String: Any]] = []

        if featureManager.isEnabled(.determineAccessibilityFromStructure) {
            let substructure = try sourceKit.editorOpenSubstructure(sourceFile)
            rawStructures = substructure[SourceKit.Key.substructure.rawValue] as? [[String: Any]] ?? []
        }

        if let rawEntities = index[SourceKit.Key.entities.rawValue] as? [[String: Any]] {
            _ = try self.parse(rawEntities: rawEntities,
                               rawStructures: rawStructures,
                               file: sourceFile,
                               parent: nil)
        }
    }

    private func parseUnusedParams(_ sourceFile: SourceFile, _ sourceKit: SourceKit) throws {
        let analyzer = UnusedParameterAnalyzer()
        let params = try analyzer.analyze(file: sourceFile.path, parseProtocols: true)

        for param in params {
            guard let functionDecl = try functionDecl(for: param, sourceKit) else { continue }

            let paramDecl = param.declaration
            paramDecl.parent = functionDecl
            functionDecl.unusedParameters.insert(paramDecl)
            graph.add(paramDecl)
        }
    }

    private var functionDecls: [SourceLocation: Declaration] = [:]

    private func functionDecl(for param: Parameter, _ sourceKit: SourceKit) throws -> Declaration? {
        guard let function = param.function,
            let offset = function.location.offset else { return nil }

        if let decl = functionDecls[function.location] {
            return decl
        }

        let info = try sourceKit.cursorInfo(file: function.location.file,
                                            offset: offset)

        guard let rawKind = info[SourceKit.Key.kind.rawValue] as? String,
            let usr = info[SourceKit.Key.usr.rawValue] as? String
            else {
                logger.warn("Failed to parse cursor info for function '\(function.fullName)' at '\(function.location)':\n\(info)")
                return nil
        }

        guard let kind = Declaration.Kind(rawValue: rawKind),
            kind.isFunctionKind
            else {
                logger.warn("Unexpected function kind '\(rawKind)'.")
                return nil
        }

        guard let functionDecl = graph.explicitDeclaration(withUsr: usr) else {
            logger.warn("No such function declaration with USR '\(usr)'")
            return nil
        }

        functionDecls[function.location] = functionDecl
        return functionDecl
    }

    private func parse(rawEntities: [[String: Any]], rawStructures: [[String: Any]], file: SourceFile, parent: Entity?) throws -> (declarations: Set<Declaration>, references: Set<Reference>) {
        var declarations: Set<Declaration> = []
        var references: Set<Reference> = []

        for rawEntity in rawEntities {
            guard let kindName = rawEntity[SourceKit.Key.kind.rawValue] as? String else {
                throw PeripheryKitError.swiftIndexingError(message: "Expected '\(SourceKit.Key.kind.rawValue)' in entity: \(rawEntity)")
            }

            var entity: Entity
            var substructures: [[String: Any]] = []

            if let kind = Declaration.Kind(rawValue: kindName) {
                let result = try build(kind: kind, entity: rawEntity, structures: rawStructures, file: file)
                entity = result.declaration
                substructures = result.substructures
            } else if let kind = Reference.Kind(rawValue: kindName) {
                let reference = try build(kind: kind, entity: rawEntity, file: file, parent: parent, isRelated: false)
                entity = reference
            } else {
                throw PeripheryKitError.swiftIndexingError(message: "Unhandled entity kind '\(kindName)'")
            }

            entity.parent = parent

            if let rawEntities = rawEntity[SourceKit.Key.entities.rawValue] as? [[String: Any]] {
                let (declarations, references) = try parse(rawEntities: rawEntities, rawStructures: substructures, file: file, parent: entity)
                entity.declarations = declarations
                entity.references = references
            }

            if let rawReferences = rawEntity[SourceKit.Key.related.rawValue] as? [[String: Any]] {
                if let declaration = entity as? Declaration {
                    declaration.related = try parse(rawRelatedReferences: rawReferences, file: file, parent: declaration)
                } else {
                    throw PeripheryKitError.swiftIndexingError(message: "Expected only declarations to have related references.")
                }
            }

            if let declaration = entity as? Declaration {
                if let rawAttributes = rawEntity[SourceKit.Key.attributes.rawValue] as? [[String: Any]] {
                    declaration.attributes = parse(rawAttributes: rawAttributes)
                }

                declarations.insert(declaration)
            } else if let reference = entity as? Reference {
                references.insert(reference)
            }
        }

        return (declarations, references)
    }

    private func parse(rawRelatedReferences: [[String: Any]], file: SourceFile, parent: Entity) throws -> Set<Reference> {
        let references: [Reference] = try rawRelatedReferences.map { rawReference in
            guard let kindName = rawReference[SourceKit.Key.kind.rawValue] as? String else {
                throw PeripheryKitError.swiftIndexingError(message: "Expected '\(SourceKit.Key.kind.rawValue)' in related reference: \(rawReference)")
            }

            if let kind = Reference.Kind(rawValue: kindName) {
                let reference = try build(kind: kind, entity: rawReference, file: file, parent: parent, isRelated: true)
                reference.parent = parent
                return reference
            } else {
                throw PeripheryKitError.swiftIndexingError(message: "Unhandled related reference kind '\(kindName)'")
            }
        }

        return Set(references)
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

    private func build(kind: Declaration.Kind, entity: [String: Any], structures: [[String: Any]]?, file: SourceFile) throws -> (declaration: Declaration, substructures: [[String: Any]]) {
        guard let usr = entity[SourceKit.Key.usr.rawValue] as? String,
            let line = entity[SourceKit.Key.line.rawValue] as? Int64,
            let column = entity[SourceKit.Key.column.rawValue] as? Int64 else {
                throw PeripheryKitError.swiftIndexingError(message: "Failed to parse declaration entity: \(entity)")
        }

        let location = SourceLocation(file: file, line: line, column: column)
        let declaration = Declaration(kind: kind, usr: usr, location: location)
        var substructures: [[String: Any]] = []

        if let name = entity[SourceKit.Key.name.rawValue] as? String {
            declaration.name = name
        }

        if let isImplicit = entity[SourceKit.Key.isImplicit.rawValue] as? Bool {
            declaration.isImplicit = isImplicit
        }

        if let structures = structures, let name = declaration.name {
            let matchingStructures = structures.filter {
                guard let structureKindName = $0[SourceKit.Key.kind.rawValue] as? String,
                    let structureKind = Declaration.Kind(rawValue: structureKindName) else { return false }

                var structureName = $0[SourceKit.Key.name.rawValue] as? String

                if let last = structureName?.split(separator: ".").last {
                    // Truncate e.g Notification.Name to just Name to match the index declaration.
                    structureName = String(last)
                }

                return kind.isEqualToStructure(kind: structureKind) && structureName == name
            }

            for structure in matchingStructures {
                if let accessibilityName = structure[SourceKit.Key.accessibility.rawValue] as? String {
                    if let accessibility = Accessibility(rawValue: accessibilityName) {
                        declaration.structureAccessibility = accessibility
                    } else {
                        throw PeripheryKitError.swiftIndexingError(message: "Unhandled accessibility '\(accessibilityName)'")
                    }
                }
                substructures += structure[SourceKit.Key.substructure.rawValue] as? [[String: Any]] ?? []
            }
        }

        graph.add(declaration)
        return (declaration, substructures)
    }

    private func build(kind: Reference.Kind, entity: [String: Any], file: SourceFile, parent: Entity?, isRelated: Bool) throws -> Reference {
        guard let usr = entity[SourceKit.Key.usr.rawValue] as? String else {
            throw PeripheryKitError.swiftIndexingError(message: "Failed to parse reference entity: \(entity)")
        }

        var line = entity[SourceKit.Key.line.rawValue] as? Int64
        var column = entity[SourceKit.Key.column.rawValue] as? Int64

        if let parent = parent {
            // Some related references do not have a line or column, therefore we use those from
            // the parent declaration.
            if line == nil {
                line = parent.location.line
            }

            if column == nil {
                column = parent.location.column
            }
        }

        let location = SourceLocation(file: file, line: line, column: column)
        let reference = Reference(kind: kind, usr: usr, location: location)
        reference.isRelated = isRelated

        if let name = entity[SourceKit.Key.name.rawValue] as? String {
            reference.name = name
        }

        if let receiverUsr = entity[SourceKit.Key.receiverUsr.rawValue] as? String {
            reference.receiverUsr = receiverUsr
        }

        graph.add(reference)
        return reference
    }
}
