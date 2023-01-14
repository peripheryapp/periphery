import Foundation
import Shared

// https://bugs.swift.org/browse/SR-13792
// The index store does not contain references to `appendInterpolation` functions from their use in string literals.
final class StringInterpolationAppendInterpolationRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        graph.declarations(ofKind: .extensionStruct)
            .forEach {
                $0.declarations.filter {
                    $0.kind == .functionMethodInstance &&
                        ($0.name ?? "").hasPrefix("appendInterpolation(")
                }.forEach {
                    graph.markRetained($0)
                }
            }
    }
}
