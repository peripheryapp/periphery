import Configuration
import Foundation
import Shared

final class EquatableHashablePropertyRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        for decl in graph.declarations(ofKinds: Declaration.Kind.discreteConformableKinds) {
            guard decl.kind != .class, shouldRetainProperties(of: decl) else { continue }

            for decl in decl.declarations {
                guard decl.kind == .varInstance else { continue }

                graph.markRetained(decl)
            }
        }
    }

    private func shouldRetainProperties(of decl: Declaration) -> Bool {
        if configuration.retainEquatableProperties, graph.isEquatable(decl) {
            return true
        }

        if configuration.retainHashableProperties, graph.isHashable(decl) {
            return true
        }

        return false
    }
}
