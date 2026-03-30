import Configuration
import Foundation
import Shared

final class AncestralReferenceEliminator: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        for declaration in graph.rootDeclarations {
            var stack = declaration.usrIDs
            eliminateAncestralReferences(in: declaration, stack: &stack)
        }
    }

    // Uses an Array rather than a Set for the ancestor stack because the stack depth is
    // typically 5-20 elements, where linear scan of contiguous integers is cheaper than hashing.
    private func eliminateAncestralReferences(in declaration: Declaration, stack: inout [USRID]) {
        guard !graph.isRetained(declaration) else { return }

        eliminateAncestralReferences(in: declaration.references, stack: stack)

        for childDeclaration in declaration.declarations {
            let prevCount = stack.count
            stack.append(contentsOf: childDeclaration.usrIDs)
            eliminateAncestralReferences(in: childDeclaration, stack: &stack)
            stack.removeSubrange(prevCount...)
        }
    }

    private func eliminateAncestralReferences(in references: [Reference], stack: [USRID]) {
        for reference in references {
            if stack.contains(reference.usrID) {
                graph.remove(reference)
            }
        }
    }
}
