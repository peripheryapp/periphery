import Configuration
import Shared

final class RedundantFilePrivateAccessibilityMarker: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() throws {
        guard !configuration.disableRedundantFilePrivateAnalysis else { return }

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
        if decl.accessibility.isExplicitly(.fileprivate) {
            if !graph.isRetained(decl), !isReferencedOutsideFile(decl) {
                mark(decl)
                markExplicitFilePrivateDescendentDeclarations(from: decl)
            }
        } else {
            markExplicitFilePrivateDescendentDeclarations(from: decl)
        }
    }

    private func validateExtension(_ decl: Declaration) throws {
        if decl.accessibility.isExplicitly(.fileprivate) {
            if let extendedDecl = try? graph.extendedDeclaration(forExtension: decl),
               graph.redundantFilePrivateAccessibility.keys.contains(extendedDecl) {
                mark(decl)
            }
        }
    }

    private func mark(_ decl: Declaration) {
        guard !graph.isRetained(decl) else { return }
        graph.markRedundantFilePrivateAccessibility(decl, file: decl.location.file)
    }

    private func markExplicitFilePrivateDescendentDeclarations(from decl: Declaration) {
        for descDecl in descendentFilePrivateDeclarations(from: decl) {
            mark(descDecl)
        }
    }

    private func isReferencedOutsideFile(_ decl: Declaration) -> Bool {
        let referenceFiles = graph.references(to: decl).map(\.location.file)
        return referenceFiles.contains { $0 != decl.location.file }
    }

    private func descendentFilePrivateDeclarations(from decl: Declaration) -> Set<Declaration> {
        let filePrivateDeclarations = decl.declarations.filter { !$0.isImplicit && $0.accessibility.isExplicitly(.fileprivate) }
        return filePrivateDeclarations.flatMapSet { descendentFilePrivateDeclarations(from: $0) }.union(filePrivateDeclarations)
    }
} 