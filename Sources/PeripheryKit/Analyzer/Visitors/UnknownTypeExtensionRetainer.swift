import Foundation

/// Retains extensions of types for which we do not have a declaration.
final class UnknownTypeExtensionRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() throws {
        try Declaration.Kind.extensionKinds.forEach { try retainUnknownExtensions(kind: $0) }
    }

    // MARK: - Private

    private func retainUnknownExtensions(kind: Declaration.Kind) throws {
        for extensionDeclaration in graph.declarations(ofKind: kind) {
            if try graph.extendedDeclaration(forExtension: extensionDeclaration) == nil {
                extensionDeclaration.markRetained(reason: .unknownTypeExtension)
            }
        }
    }
}
