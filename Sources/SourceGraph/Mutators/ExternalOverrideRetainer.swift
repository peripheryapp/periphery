import Configuration
import Foundation
import Shared

/// Retains instance functions/vars that override external declarations.
///
/// It's not possible to determine if a declaration that overrides an external declaration is used,
/// as the external implementation may call the overridden declaration.
final class ExternalOverrideRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        for decl in graph.declarations(ofKinds: Declaration.Kind.overrideKinds) {
            guard decl.isOverride else { continue }

            let matchingRelatedRefs = decl.related.filter {
                $0.declarationKind == decl.kind &&
                    $0.name == decl.name &&
                    $0.location == decl.location
            }

            let hasExternalMatch = matchingRelatedRefs.contains { graph.declaration(withUsr: $0.usr) == nil }

            if hasExternalMatch {
                // One or more matching related declarations are external.
                graph.markRetained(decl)
            }
        }
    }
}
