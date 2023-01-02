import Foundation
import Shared

final class PropertyWrapperRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let specialProperties = ["wrappedValue", "projectedValue"]

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        for decl in graph.declarations(ofKinds: Declaration.Kind.toplevelAttributableKind) {
            if decl.attributes.contains("propertyWrapper") {
                decl.declarations
                    .filter { $0.kind == .varInstance && specialProperties.contains($0.name ?? "") }
                    .forEach { graph.markRetained($0) }
            }
        }
    }
}
