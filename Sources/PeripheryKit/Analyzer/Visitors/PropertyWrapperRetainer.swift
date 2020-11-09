import Foundation
import PathKit
import Shared

final class PropertyWrapperRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph
    private let specialProperties = ["wrappedValue", "projectedValue"]

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        for decl in graph.declarations(ofKinds: [.struct, .class]) {
            if decl.attributes.contains("propertyWrapper") {
                decl.declarations
                    .filter { $0.kind == .varInstance && specialProperties.contains($0.name ?? "") }
                    .forEach { $0.markRetained() }
            }
        }
    }
}
