import Foundation

final class DeclarationMarker: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        removeErroneousProtocolReferences()
        markReachable(graph.retainedDeclarations)

        let rootReferencedDeclarations = Set(graph.rootReferences.flatMap { declarationsReferenced(by: $0) })
        markReachable(rootReferencedDeclarations)

        ignoreUnreachableDescendents(in: graph.rootDeclarations,
                                     unreachableDeclarations: graph.unreachableDeclarations)
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

    private func markReachable(_ declarations: Set<Declaration>) {
        for declaration in declarations {
            let count = graph.incrementReachable(declaration)

            if count == 1 {
                // First time seeing this declaration.
                markReachable(declarationsReferenced(by: declaration))
            }
        }
    }

    private func declarationsReferenced(by declaration: Declaration) -> Set<Declaration> {
        let allReferences = declaration.references.union(declaration.related)
        return Set(allReferences.flatMap { declarationsReferenced(by: $0) })
    }

    private func declarationsReferenced(by reference: Reference) -> Set<Declaration> {
        var declarations: Set<Declaration> = []

        if let declaration = graph.explicitDeclaration(withUsr: reference.usr) {
            declarations.insert(declaration)
        }

        return declarations
    }

    private func ignoreUnreachableDescendents(in decls: Set<Declaration>, unreachableDeclarations: Set<Declaration>) {
        for decl in decls {
            guard !decl.declarations.isEmpty || !decl.unusedParameters.isEmpty
                else { continue }

            if unreachableDeclarations.contains(decl) {
                ignoreDescendents(of: decl)
            } else {
                ignoreUnreachableDescendents(in: decl.declarations,
                                             unreachableDeclarations: unreachableDeclarations)
            }
        }
    }

    private func ignoreDescendents(of decl: Declaration) {
        guard !graph.isIgnored(decl) else {
            // This declaration is itself ignored, thus is descendents are too already.
            return
        }

        decl.descendentDeclarations.forEach {
            graph.markIgnored($0)

            // If this declaration is retained, we need to unretain it and decrement references it holds.
            if graph.isRetained($0) {
                graph.unmarkRetained($0)

                // Retained declarations are also previously marked as reachable, so decrement.
                graph.decrementReachable($0)

                decrementReferences(from: $0, callers: [$0])
            }
        }
    }

    private func decrementReferences(from declaration: Declaration, callers: Set<Declaration>) {
        var declarationsToIgnore: [Declaration] = []

        for decl in declarationsReferenced(by: declaration) {
            let refCount = graph.decrementReachable(decl)

            if graph.isIgnored(decl) {
                // This declaration is ignored, thus its references have already been decremented.
                continue
            }

            if callers.contains(decl) {
                // Already seen this declaration, avoid traversing cyclic references.
                continue
            }

            decrementReferences(from: decl, callers: callers.union([decl]))

            if refCount == 0 {
                // This declaration is now unreachable, ignore its descendents once we're done decrementing references.
                declarationsToIgnore.append(decl)
            }
        }

        declarationsToIgnore.forEach { ignoreDescendents(of: $0) }
    }
}
