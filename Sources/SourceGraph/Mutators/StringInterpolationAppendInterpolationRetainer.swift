import Foundation
import Shared

// https://github.com/apple/swift/issues/56189
// The index store does not contain references to `appendInterpolation` functions from their use in string literals.
final class StringInterpolationAppendInterpolationRetainer: SourceGraphMutator {
    // swiftlint:disable:previous type_name
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
