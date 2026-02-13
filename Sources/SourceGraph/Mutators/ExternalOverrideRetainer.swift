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

            for relatedRef in decl.related {
                if relatedRef.declarationKind == decl.kind,
                   relatedRef.name == decl.name,
                   relatedRef.location == decl.location
                {
                    if graph.declaration(withUsr: relatedRef.usr) == nil {
                        // The related decl is external.
                        graph.markRetained(decl)
                    }

                    break
                }
            }
        }
    }
}
