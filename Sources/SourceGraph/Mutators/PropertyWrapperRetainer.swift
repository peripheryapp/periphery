import Foundation
import Shared

final class PropertyWrapperRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let specialProperties = ["wrappedValue", "projectedValue"]

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        for decl in graph.declarations(ofKinds: Declaration.Kind.toplevelAttributableKind) where decl.attributes.contains("propertyWrapper") {
            decl.declarations
                .filter { $0.kind == .varInstance && specialProperties.contains($0.name ?? "") }
                .forEach { graph.markRetained($0) }
        }
    }
}
