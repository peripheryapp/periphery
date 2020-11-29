import Foundation

final class AssociatedTypeTypeAliasReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() throws {
        for alias in graph.declarations(ofKind: .typealias) {
            let related = alias.related.first { $0.kind == .associatedtype }

            if let related = related {
                if let associated = graph.explicitDeclaration(withUsr: related.usr) {
                    graph.remove(related)

                    for usr in alias.usrs {
                        let inverseRelated = Reference(kind: .typealias, usr: usr, location: alias.location)
                        inverseRelated.isRelated = true
                        inverseRelated.parent = associated
                        inverseRelated.name = alias.name
                        graph.add(inverseRelated, from: associated)
                    }
                } else {
                    // The associatedtype is external, we must retain the typealias as it may also be used externally.
                    graph.markRetained(alias)
                }
            }
        }
    }
}
