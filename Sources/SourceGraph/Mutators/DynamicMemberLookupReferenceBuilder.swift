import Foundation
import Shared

final class DynamicMemberLookupReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() throws {
        for decl in graph.declarations(ofKind: .functionSubscript) {
            if decl.name == "subscript(dynamicMember:)", decl.parent?.attributes.contains("dynamicMemberLookup") ?? false {
                graph.markRetained(decl)
            }
        }
    }
}
