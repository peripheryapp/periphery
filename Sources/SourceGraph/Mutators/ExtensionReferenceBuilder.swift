import Foundation
import Shared

/// Folds all references and declarations that exist within an extension into the
/// class/struct that is being extended and removes the extension declaration.
final class ExtensionReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
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
                referenceExtendedTypeAliases(of: extendedTypeReference, from: extensionDeclaration)
                continue
            }

            referenceExtendedTypeAliases(of: extendedTypeReference, from: extendedDeclaration)

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

    private func referenceExtendedTypeAliases(of extendedTypeReference: Reference, from extensionDeclaration: Declaration) {
        // Extensions on type aliases reference the existing type, not the alias.
        // We need to find the typealias and build a reference to it.
        let extendedTypeReferences = graph.allReferencesByUsr[extendedTypeReference.usr, default: []]

        for reference in extendedTypeReferences {
            guard let aliasDecl = reference.parent, aliasDecl.kind == .typealias else { continue }
            for usr in aliasDecl.usrs {
                let aliasReference = Reference(kind: .typealias, usr: usr, location: extensionDeclaration.location)
                aliasReference.name = aliasDecl.name
                graph.add(aliasReference, from: extensionDeclaration)
            }
        }
    }
}
