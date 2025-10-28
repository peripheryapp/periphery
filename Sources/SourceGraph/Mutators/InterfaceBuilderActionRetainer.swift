import Configuration
import Foundation
import Shared

final class InterfaceBuilderActionRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration
    private static let actionAttributes: Set<String> = ["IBAction", "IBSegueAction"]

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        guard configuration.retainIbaction else { return }

        graph.allDeclarations
            .lazy
            .filter { !$0.attributes.isDisjoint(with: Self.actionAttributes) }
            .forEach { declaration in
                graph.markRetained(declaration)
                declaration.ancestralDeclarations.forEach { graph.markRetained($0) }
            }
    }
}
