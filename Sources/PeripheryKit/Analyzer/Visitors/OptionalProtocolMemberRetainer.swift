import Foundation
import Shared

/// Workaround for bug present in Swift 5.3 and below.
final class OptionalProtocolMemberRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        if SwiftVersion.current.version.isVersion(lessThan: "5.4") {
            for decl in graph.declarations(ofKind: .protocol) {
                decl.declarations
                    .filter { $0.modifiers.contains("optional") }
                    .forEach { graph.markRetained($0) }
            }
        }
    }
}
