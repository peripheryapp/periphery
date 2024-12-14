import Configuration
import Foundation
import Shared

/// Retains instance functions/vars that override external declarations.
///
/// It's not possible to determine if a declaration that overrides an external declaration is used,
/// as the external implementation may call the overridden declaration.
final class ExternalOverrideRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let isSwift60FixEnabled: Bool

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion: SwiftVersion) {
        self.graph = graph
        isSwift60FixEnabled = swiftVersion.version.isVersion(greaterThanOrEqualTo: "6.0") &&
            swiftVersion.version.isVersion(lessThan: "6.1")
    }

    func mutate() {
        for decl in graph.declarations(ofKinds: Declaration.Kind.overrideKinds) {
            guard decl.isOverride else { continue }

            var didIdentifyRelatedRef = false

            for relatedRef in decl.related {
                if relatedRef.kind == decl.kind,
                   relatedRef.name == decl.name,
                   relatedRef.location == decl.location
                {
                    didIdentifyRelatedRef = true

                    if graph.explicitDeclaration(withUsr: relatedRef.usr) == nil {
                        // The related decl is external.
                        graph.markRetained(decl)
                    }

                    break
                }
            }

            // https://github.com/swiftlang/swift/issues/76628
            if !didIdentifyRelatedRef, isSwift60FixEnabled {
                graph.markRetained(decl)
            }
        }
    }
}
