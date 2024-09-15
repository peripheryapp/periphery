import Foundation
import Shared

final class AccessibilityCascader: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() throws {
        let extensions = Declaration.Kind.extensionKinds.flatMap { graph.declarations(ofKind: $0) }
        try cascadeAccessibility(for: extensions)
        let protocols = graph.declarations(ofKind: .protocol)
        try cascadeAccessibility(for: Array(protocols))
        let enums = graph.declarations(ofKind: .enum)
        try cascadeAccessibility(for: Array(enums), only: [.enumelement])
    }

    // MARK: - Private

    private func cascadeAccessibility(for decls: [Declaration], only kinds: Set<Declaration.Kind> = []) throws {
        for decl in decls where decl.accessibility.isExplicit {
            for childDecl in decl.declarations {
                if !kinds.isEmpty, !kinds.contains(childDecl.kind) {
                    continue
                }

                if !childDecl.accessibility.isExplicit {
                    childDecl.accessibility = .init(value: decl.accessibility.value, isExplicit: false)
                }
            }
        }
    }
}
