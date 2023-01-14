import Foundation
import Shared

final class PubliclyAccessibleRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        guard configuration.retainPublic else { return }

        let declarations = Declaration.Kind.accessibleKinds.flatMap {
            graph.declarations(ofKind: $0)
        }

        let publicDeclarations = declarations.filter { $0.accessibility.value == .public || $0.accessibility.value == .open }
        
        publicDeclarations.forEach { graph.markRetained($0) }

        // Enum cases inherit the accessibility of the enum.
        publicDeclarations
            .lazy
            .filter { $0.kind == .enum }
            .flatMap { $0.declarations }
            .filter { $0.kind == .enumelement }
            .forEach { graph.markRetained($0) }
    }
}
