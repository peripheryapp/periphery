import Configuration
import Shared

final class RedundantInternalAccessibilityMarker: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.disableRedundantInternalAnalysis else { return }

        let nonExtensionKinds = graph.rootDeclarations.filter { !$0.kind.isExtensionKind }
        let extensionKinds = graph.rootDeclarations.filter(\.kind.isExtensionKind)

        for decl in nonExtensionKinds {
            try validate(decl)
        }

        for decl in extensionKinds {
            try validateExtension(decl)
        }
    }

    // MARK: - Private

    private func validate(_ decl: Declaration) throws {
        if decl.accessibility.isExplicitly(.internal) {
            if !graph.isRetained(decl) {
                let isReferencedOutside = isReferencedOutsideFile(decl)
                if !isReferencedOutside {
                    mark(decl)
                    markExplicitInternalDescendentDeclarations(from: decl)
                }
            }
        } else {
            markExplicitInternalDescendentDeclarations(from: decl)
        }
    }

    private func validateExtension(_ decl: Declaration) throws {
        if decl.accessibility.isExplicitly(.internal) {
            if let extendedDecl = try? graph.extendedDeclaration(forExtension: decl),
               graph.redundantInternalAccessibility.keys.contains(extendedDecl) {
                mark(decl)
            }
        }
    }

    private func mark(_ decl: Declaration) {
        guard !graph.isRetained(decl) else { return }
        graph.markRedundantInternalAccessibility(decl, file: decl.location.file)
    }

    private func markExplicitInternalDescendentDeclarations(from decl: Declaration) {
        for descDecl in descendentInternalDeclarations(from: decl) {
            if !graph.isRetained(descDecl) {
                let isReferencedOutside = isReferencedOutsideFile(descDecl)
                if !isReferencedOutside {
                    mark(descDecl)
                }
            }
        }
    }

    private func isReferencedOutsideFile(_ decl: Declaration) -> Bool {
        // Use graph.references(to: decl) to get all references to this declaration
        let allReferences = graph.references(to: decl)
        let referenceFiles = allReferences.map(\.location.file)
        
        let result = referenceFiles.contains { $0 != decl.location.file }
        return result
    }

    private func descendentInternalDeclarations(from decl: Declaration) -> Set<Declaration> {
        let internalDeclarations = decl.declarations.filter { !$0.isImplicit && $0.accessibility.isExplicitly(.internal) }
        return internalDeclarations.flatMapSet { descendentInternalDeclarations(from: $0) }.union(internalDeclarations)
    }
} 