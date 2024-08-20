import Foundation
import Shared

/// Folds all references and declarations that exist within an extension into the
/// class/struct that is being extended and removes the extension declaration.
final class ExtensionReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration) {
        self.graph = graph
    }

    func mutate() throws {
        try Declaration.Kind.extensionKinds.forEach { try foldExtension(kind: $0) }
    }

    // MARK: - Private

    private func foldExtension(kind: Declaration.Kind) throws {
        for extensionDeclaration in graph.declarations(ofKind: kind) {
            guard let extendedTypeReference = try graph.extendedDeclarationReference(forExtension: extensionDeclaration) else { continue }

            guard let extendedDeclaration = graph.explicitDeclaration(withUsr: extendedTypeReference.usr) else {
                // This is an extension on an external type and cannot be folded.
                graph.markRetained(extensionDeclaration)
                continue
            }

            // Don't fold protocol extensions as they must be treated differently.
            guard kind != .extensionProtocol else { continue }

            extendedDeclaration.declarations.formUnion(extensionDeclaration.declarations)
            extendedDeclaration.references.formUnion(extensionDeclaration.references)
            extendedDeclaration.related.formUnion(extensionDeclaration.related)

            if extensionDeclaration.hasCapitalSelfFunctionCall {
                extendedDeclaration.hasCapitalSelfFunctionCall = true
            }

            extensionDeclaration.declarations.forEach { $0.parent = extendedDeclaration }
            extensionDeclaration.references.forEach { $0.parent = extendedDeclaration }
            extensionDeclaration.related.forEach { $0.parent = extendedDeclaration }

            graph.markExtension(extensionDeclaration, extending: extendedDeclaration)
            graph.remove(extensionDeclaration)
        }
    }
}
