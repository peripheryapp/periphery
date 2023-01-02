import Foundation
import Shared

final class ObjCAccessibleRetainer: SourceGraphMutator {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        guard configuration.retainObjcAccessible else { return }

        Declaration.Kind.accessibleKinds
            .flatMap {
                graph.declarations(ofKind: $0)
            }
            .filter {
                $0.attributes.contains("objc") ||
                    $0.attributes.contains("objc.name") ||
                    $0.attributes.contains("objcMembers")
            }
            .forEach {
                $0.isObjcAccessible = true
                graph.markRetained($0)
            }
    }
}
