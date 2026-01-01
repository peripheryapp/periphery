import Configuration
import Foundation
import Shared

/// Retains localized string declarations from xcstrings files that are used in Swift source code.
final class LocalizedStringRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        let usedKeys = graph.usedLocalizedStringKeys

        guard !usedKeys.isEmpty else { return }

        // Find all xcstrings declarations and mark them as retained if their key is used
        for declaration in graph.allDeclarations {
            guard let name = declaration.name,
                  declaration.usrs.contains(where: { $0.hasPrefix("xcstrings:") })
            else { continue }

            if usedKeys.contains(name) {
                graph.markRetained(declaration)
            }
        }
    }
}
