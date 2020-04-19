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

            if let related = related,
                let associated = graph.explicitDeclaration(withUsr: related.usr) {
                graph.remove(related)

                let inverseRelated = Reference(kind: .typealias, usr: alias.usr, location: alias.location)
                inverseRelated.isRelated = true
                inverseRelated.parent = associated
                inverseRelated.name = alias.name
                graph.add(inverseRelated, from: associated)
            }
        }
    }
}
