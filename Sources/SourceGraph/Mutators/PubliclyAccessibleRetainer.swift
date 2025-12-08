import Configuration
import Foundation
import Shared

final class PubliclyAccessibleRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        guard configuration.retainPublic else { return }

        let declarations = Declaration.Kind.accessibleKinds.flatMap {
            graph.declarations(ofKind: $0)
        }

        let publicDeclarations = declarations.filter { $0.accessibility.value == .public || $0.accessibility.value == .open }

        // Only filter if checkSpi is configured (performance optimization)
        let declarationsToRetain: [Declaration]
        if configuration.checkSpi.isEmpty {
            declarationsToRetain = publicDeclarations
        } else {
            declarationsToRetain = publicDeclarations.filter { decl in
                !shouldCheckSpi(decl)
            }
        }

        declarationsToRetain.forEach { graph.markRetained($0) }

        // Enum cases inherit the accessibility of the enum.
        declarationsToRetain
            .lazy
            .filter { $0.kind == .enum }
            .flatMap(\.declarations)
            .filter { $0.kind == .enumelement }
            .forEach { graph.markRetained($0) }
    }

    private func shouldCheckSpi(_ declaration: Declaration) -> Bool {
        configuration.checkSpi.contains { spiName in
            declaration.attributes.contains("_spi\(spiName)")
        }
    }
}
