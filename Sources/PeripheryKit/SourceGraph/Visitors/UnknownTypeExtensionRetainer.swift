import Foundation
import Shared

/// Retains extensions of types for which we do not have a declaration.
final class UnknownTypeExtensionRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() throws {
        try Declaration.Kind.extensionKinds.forEach { try retainUnknownExtensions(kind: $0) }
    }

    // MARK: - Private

    private func retainUnknownExtensions(kind: Declaration.Kind) throws {
        for extensionDeclaration in graph.declarations(ofKind: kind) {
            if try graph.extendedDeclaration(forExtension: extensionDeclaration) == nil {
                graph.markRetained(extensionDeclaration)
            }
        }
    }
}
