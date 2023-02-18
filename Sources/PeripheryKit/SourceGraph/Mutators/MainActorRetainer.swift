import Foundation
import Shared

/// Retains all @MainActor annotated types and their initializers to workaround a Swift bug present
/// in version 5.7.
/// https://github.com/peripheryapp/periphery/issues/550
final class MainActorRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        guard SwiftVersion.current.version.isVersion(lessThanOrEqualTo: "5.7") else { return }

        for decl in graph.declarations(ofKinds: Declaration.Kind.toplevelAttributableKind) {
            if decl.attributes.contains("MainActor") {
                graph.markRetained(decl)
                decl.declarations
                    .lazy
                    .filter { $0.kind == .functionConstructor }
                    .forEach { graph.markRetained($0) }
            }
        }
    }
}
