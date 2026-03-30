import Configuration
import Foundation
import Shared

final class UsedDeclarationMarker: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        removeErroneousProtocolReferences()
        markUsed(graph.retainedDeclarations)

        for ref in graph.rootReferences {
            markUsed(from: ref)
        }

        ignoreUnusedDescendents(in: graph.rootDeclarations,
                                unusedDeclarations: graph.unusedDeclarations)
    }

    // MARK: - Private

    // Removes references from protocol member decls to conforming decls that have a dereferenced ancestor.
    private func removeErroneousProtocolReferences() {
        // When a declaration has zero references, isRetained() simplifies to
        // retainedDeclarations.contains() — no need to scan references for
        // .retained kind. When it HAS references, it's not dereferenced regardless.
        let retained = graph.retainedDeclarations
        let dereferencedDeclarations = graph.allDeclarations.filter {
            !graph.hasReferences(to: $0) && !retained.contains($0)
        }

        let dereferencedAncestors = Set(dereferencedDeclarations)
        var referencesToRemove = Set<Reference>()

        for protocolDecl in graph.declarations(ofKind: .protocol) {
            for memberDecl in protocolDecl.declarations {
                for relatedRef in memberDecl.related {
                    guard let relatedDecl = graph.declaration(withUsrID: relatedRef.usrID) else { continue }

                    let hasDereferencedAncestor = relatedDecl.ancestralDeclarations.contains {
                        dereferencedAncestors.contains($0)
                    }

                    if hasDereferencedAncestor {
                        referencesToRemove.insert(relatedRef)
                    }
                }
            }
        }

        for reference in referencesToRemove {
            graph.remove(reference)
        }
    }

    private func markUsed(_ declarations: some Collection<Declaration>) {
        for decl in declarations {
            markUsed(decl)
        }
    }

    private func markUsed(from reference: Reference) {
        guard let decl = graph.declaration(withUsrID: reference.usrID) else { return }

        markUsed(decl)
    }

    private func markUsed(_ decl: Declaration) {
        guard !graph.isUsed(decl) else { return }

        graph.markUsed(decl)

        for ref in decl.references {
            if let d = graph.declaration(withUsrID: ref.usrID) {
                markUsed(d)
            }
        }

        for ref in decl.related {
            if let d = graph.declaration(withUsrID: ref.usrID) {
                markUsed(d)
            }
        }
    }

    private func ignoreUnusedDescendents(in decls: some Collection<Declaration>, unusedDeclarations: Set<Declaration>) {
        for decl in decls {
            guard !decl.declarations.isEmpty || !decl.unusedParameters.isEmpty
            else { continue }

            if unusedDeclarations.contains(decl) {
                decl.forEachDescendentDeclaration { graph.markIgnored($0) }
            } else {
                ignoreUnusedDescendents(in: decl.declarations,
                                        unusedDeclarations: unusedDeclarations)
            }
        }
    }
}
