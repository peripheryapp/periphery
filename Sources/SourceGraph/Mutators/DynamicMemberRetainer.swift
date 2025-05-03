import Configuration
import Foundation
import Shared

@MainActor
final class DynamicMemberRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() throws {
        for decl in graph.declarations(ofKind: .functionSubscript) {
            if decl.name == "subscript(dynamicMember:)", decl.parent?.attributes.contains("dynamicMemberLookup") ?? false {
                graph.markRetained(decl)
            }
        }

        for decl in graph.declarations(ofKinds: Declaration.Kind.functionKinds.union(Declaration.Kind.variableKinds)) {
            if decl.attributes.contains("_dynamicReplacement") {
                graph.markRetained(decl)
            }
        }
    }
}
