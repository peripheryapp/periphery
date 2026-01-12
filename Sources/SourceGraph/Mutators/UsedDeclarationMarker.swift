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

        // Pre-compute preview-only declarations for efficient lookup.
        // A declaration is preview-only if ALL its non-root references come from
        // ignored declarations (like #Preview macro machinery).
        // Example: MyPreviewOnlyView is ONLY referenced by makePreview() (which is ignored).
        let previewOnlyDeclarations = computePreviewOnlyDeclarations()

        // Process root references (protocol conformances, etc.) but skip those targeting
        // preview-only code. Even though a root reference exists (View conformance), we skip
        // it so MyPreviewOnlyView remains unused and gets reported.
        for rootRef in graph.rootReferences {
            let targetDecls = declarationsReferenced(by: rootRef)
            let hasActualUsage = targetDecls.contains { !previewOnlyDeclarations.contains($0) }
            if hasActualUsage {
                markUsed(targetDecls)
            }
        }
        ignoreUnusedDescendents(in: graph.rootDeclarations,
                                unusedDeclarations: graph.unusedDeclarations)
    }

    // MARK: - Private

    private func computePreviewOnlyDeclarations() -> Set<Declaration> {
        let previewOnly = graph.allDeclarations.filter { decl in
            let refs = graph.references(to: decl)
            guard !refs.isEmpty else { return false }

            let nonRootRefs = refs.filter { $0.parent != nil }

            // Declaration is preview-only if all non-root references come from ignored declarations
            return !nonRootRefs.isEmpty && nonRootRefs.allSatisfy { ref in
                guard let parent = ref.parent else { return false }

                return graph.ignoredDeclarations.contains(parent)
            }
        }
        return Set(previewOnly)
    }

    // Removes references from protocol member decls to conforming decls that have a dereferenced ancestor.
    private func removeErroneousProtocolReferences() {
        for protocolDecl in graph.declarations(ofKind: .protocol) {
            for memberDecl in protocolDecl.declarations {
                for relatedRef in memberDecl.related {
                    guard let relatedDecl = graph.declaration(withUsr: relatedRef.usr) else { continue }

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

            // Skip processing references FROM ignored declarations (like #Preview machinery).
            // This prevents preview code from marking the code it references as "used".
            // Example: makePreview() is ignored. When we mark it as used (above), we then
            // check if it's ignored. Since it is, we skip processing its references to
            // MyPreviewOnlyView, so MyPreviewOnlyView stays unused.
            let shouldProcessReferences = !graph.ignoredDeclarations.contains(declaration)

            if shouldProcessReferences {
                for ref in declaration.references {
                    markUsed(declarationsReferenced(by: ref))
                }

                for ref in declaration.related {
                    markUsed(declarationsReferenced(by: ref))
                }
            }
        }
    }

    private func declarationsReferenced(by reference: Reference) -> Set<Declaration> {
        var declarations: Set<Declaration> = []

        if let declaration = graph.declaration(withUsr: reference.usr) {
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
