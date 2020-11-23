import Foundation

final class AncestralReferenceEliminator: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        for declaration in graph.rootDeclarations {
            eliminateAncestralReferences(in: declaration, stack: [declaration])
        }
    }

    private func eliminateAncestralReferences(in declaration: Declaration, stack: [Declaration]) {
        guard !declaration.isRetained else { return }

        eliminateAncestralReferences(in: declaration.references, stack: stack)

        for childDeclaration in declaration.declarations {
            let newStack = stack + [childDeclaration]
            eliminateAncestralReferences(in: childDeclaration, stack: newStack)
        }
    }

    private func anyDeclarations(in declarations: [Declaration], areReferencedBy reference: Reference) -> Bool {
        let usrs = declarations.flatMap { $0.usrs }
        return usrs.contains(reference.usr)
    }

    private func eliminateAncestralReferences(in references: Set<Reference>, stack: [Declaration]) {
        for reference in references {
            if anyDeclarations(in: stack, areReferencedBy: reference) {
                graph.remove(reference)
            }

            eliminateAncestralReferences(in: reference.references, stack: stack)
        }
    }
}
