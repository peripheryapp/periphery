import Foundation
import Shared

/// Workaround for https://github.com/apple/swift/issues/61509.
final class LetShorthandPropertyReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() throws {
        for containingDecl in graph.letShorthandContainerDeclarations {
            for potentialReferencedDecl in containingDecl.parent?.declarations ?? [] {
                guard let name = potentialReferencedDecl.name else { continue }

                if containingDecl.letShorthandIdentifiers.contains(name),
                   let kind = potentialReferencedDecl.kind.referenceEquivalent {
                     for usr in potentialReferencedDecl.usrs {
                         let reference = Reference(kind: kind, usr: usr, location: containingDecl.location)
                         reference.name = name
                         graph.add(reference)
                         containingDecl.references.insert(reference)
                     }
                }
            }
        }
    }
}
