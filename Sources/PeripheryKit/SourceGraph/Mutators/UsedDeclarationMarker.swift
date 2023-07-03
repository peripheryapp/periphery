import Foundation
import Shared

final class UsedDeclarationMarker: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        removeErroneousProtocolReferences()
        markUsed(graph.retainedDeclarations)

        let rootReferencedDeclarations = graph.rootReferences.flatMapSet { declarationsReferenced(by: $0) }
        markUsed(rootReferencedDeclarations)

        ignoreUnusedDescendents(in: graph.rootDeclarations,
                                unusedDeclarations: graph.unusedDeclarations)
    }

    // MARK: - Private

    // Removes references from protocol member decls to conforming decls that have a dereferenced ancestor.
    private func removeErroneousProtocolReferences() {
        for protocolDecl in graph.declarations(ofKind: .protocol) {
            for memberDecl in protocolDecl.declarations {
                for relatedRef in memberDecl.related {
                    guard let relatedDecl = graph.explicitDeclaration(withUsr: relatedRef.usr) else { continue }

                    let hasDereferencedAncestor = relatedDecl.ancestralDeclarations.contains {
                        !(graph.isRetained($0) || graph.hasReferences(to: $0))
                    }

                    if hasDereferencedAncestor {
                        graph.remove(relatedRef)
                    }
                }
            }
        }
    }

    private func markUsed(_ declarations: Set<Declaration>) {
        for declaration in declarations {
            guard !graph.isUsed(declaration) else { continue }

            graph.markUsed(declaration)
            markUsed(declarationsReferenced(by: declaration))
        }
    }

    private func declarationsReferenced(by declaration: Declaration) -> Set<Declaration> {
        let allReferences = declaration.references.union(declaration.related)
        return allReferences.flatMapSet { declarationsReferenced(by: $0) }
    }

    private func declarationsReferenced(by reference: Reference) -> Set<Declaration> {
        var declarations: Set<Declaration> = []

        if let declaration = graph.explicitDeclaration(withUsr: reference.usr) {
            declarations.insert(declaration)
        }

        return declarations
    }

    private func ignoreUnusedDescendents(in decls: Set<Declaration>, unusedDeclarations: Set<Declaration>) {
        for decl in decls {
            guard !decl.declarations.isEmpty || !decl.unusedParameters.isEmpty
                else { continue }

            if unusedDeclarations.contains(decl) {
                decl.descendentDeclarations.forEach { graph.markIgnored($0) }
            } else {
                ignoreUnusedDescendents(in: decl.declarations,
                                        unusedDeclarations: unusedDeclarations)
            }
        }
    }
}
