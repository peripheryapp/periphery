import Configuration
import Foundation
import Shared
import SystemPackage

/// Treats multiple generated declarations that map back to the same source declaration via
/// `periphery:override` as equivalent. If any equivalent declaration is used, the source
/// declaration is used and the others should not be reported as unused.
final class EquivalentDeclarationMarker: SourceGraphMutator {
    private struct Key: Hashable {
        let path: FilePath
        let line: Int
        let column: Int
        let kind: String
        let name: String
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        let overriddenDeclarations: [(key: Key, declaration: Declaration)] = graph.allDeclarations.compactMap { declaration in
            guard let (path, line, column) = declaration.commentCommands.locationOverride else {
                return nil
            }

            let kind = declaration.commentCommands.kindOverride ?? declaration.kind.rawValue
            return (key: Key(path: path, line: line, column: column, kind: kind, name: declaration.name), declaration: declaration)
        }
        let declarationsByKey = Dictionary(grouping: overriddenDeclarations, by: \.key)

        for groupedDeclarations in declarationsByKey.values {
            let declarations = groupedDeclarations.map(\.declaration)
            guard declarations.count > 1 else { continue }
            guard declarations.contains(where: graph.isUsed) else { continue }
            declarations.forEach { graph.markUsed($0) }
        }
    }
}
