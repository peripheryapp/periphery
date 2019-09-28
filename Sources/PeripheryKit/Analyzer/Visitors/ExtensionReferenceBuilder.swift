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

            // Workaround for bug introduced in Xcode 10.2.
            // The extension declaration contains duplicate declarations with the same USR as those in the
            // extended declaration, but without a name. We must therefore merge these declarations and discard
            // of the nameless declaration within the extension.
            for decl in extensionDeclaration.declarations.filter({ $0.name == nil }) {
                if let matchingDecl = extendedDeclaration.declarations.first(where: { $0.usr == decl.usr }) {
                    matchingDecl.references.formUnion(decl.references)
                    matchingDecl.related.formUnion(decl.references)

                    decl.references.forEach { $0.parent = matchingDecl }
                    decl.related.forEach { $0.parent = matchingDecl }

                    extensionDeclaration.declarations.remove(decl)
                }
            }

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
