import Foundation

/// Folds all references and declarations that exist within an extension into the
/// class/struct that is being extended and removes the extension declaration.
final class ExtensionReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() throws {
        // Don't fold protocol extensions as they must be treated differently.
        let kinds = Declaration.Kind.extensionKinds.subtracting([.extensionProtocol])
        try kinds.forEach { try foldExtension(kind: $0) }
    }

    // MARK: - Private

    private func foldExtension(kind: Declaration.Kind) throws {
        for extensionDeclaration in graph.declarations(ofKind: kind) {
            guard let extendedDeclaration = try graph.extendedDeclaration(forExtension: extensionDeclaration) else { continue }

            extendedDeclaration.declarations.formUnion(extensionDeclaration.declarations)
            extendedDeclaration.references.formUnion(extensionDeclaration.references)
            extendedDeclaration.related.formUnion(extensionDeclaration.related)

            extensionDeclaration.declarations.forEach { $0.parent = extendedDeclaration }
            extensionDeclaration.references.forEach { $0.parent = extendedDeclaration }
            extensionDeclaration.references.forEach { $0.parent = extendedDeclaration }

            graph.remove(extensionDeclaration)
        }
    }
}
