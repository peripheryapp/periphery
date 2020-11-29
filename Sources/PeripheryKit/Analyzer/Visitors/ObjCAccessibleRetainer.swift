import Foundation
import Shared

final class ObjCAccessibleRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph, configuration: inject())
    }

    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func visit() {
        guard configuration.retainObjcAnnotated else { return }

        let declarations = Declaration.Kind.accessibleKinds.flatMap {
            graph.declarations(ofKind: $0)
        }

        let objcDeclarations = declarations.filter {
            $0.attributes.contains("objc") ||
            $0.attributes.contains("objc.name") ||
            $0.attributes.contains("objcMembers")
        }
        objcDeclarations.forEach { graph.markRetained($0) }
    }
}
