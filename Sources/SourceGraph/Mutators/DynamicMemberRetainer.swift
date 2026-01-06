import Configuration
import Foundation
import Shared

final class DynamicMemberRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() throws {
        for decl in graph.declarations(ofKind: .functionSubscript) {
            if decl.name == "subscript(dynamicMember:)", decl.parent?.attributes.contains(where: { $0.name == "dynamicMemberLookup" }) ?? false {
                graph.markRetained(decl)
            }
        }

        for decl in graph.declarations(ofKinds: Declaration.Kind.functionKinds.union(Declaration.Kind.variableKinds)) {
            if decl.attributes.contains(where: { $0.name == "_dynamicReplacement" }) {
                graph.markRetained(decl)
            }
        }
    }
}
