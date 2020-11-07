import Foundation

// https://bugs.swift.org/browse/SR-13792
// The index store does not contain references to `appendInterpolation` functions from their use in string literals.
final class StringInterpolationAppendInterpolationRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        graph.declarations(ofKind: .extensionStruct)
            .forEach {
                $0.declarations.filter {
                    $0.kind == .functionMethodInstance &&
                        ($0.name ?? "").hasPrefix("appendInterpolation(")
                }.forEach {
                    $0.markRetained()
                }
            }
    }
}
