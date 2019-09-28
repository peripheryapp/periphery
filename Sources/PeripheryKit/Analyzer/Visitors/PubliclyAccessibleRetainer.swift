import Foundation

final class PubliclyAccessibleRetainer: SourceGraphVisitor {
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
        guard configuration.retainPublic else { return }

        let declarations = Declaration.Kind.accessibleKinds.flatMap {
            graph.declarations(ofKind: $0)
        }

        let publicDeclarations = declarations.filter { $0.accessibility == .public ||  $0.accessibility == .open }
        publicDeclarations.forEach { $0.markRetained(reason: .publicAccessible) }
    }
}
