import Foundation
import Shared

/// Retains static methods used by the Result Builder language feature.
final class ResultBuilderRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let resultBuilderMethods = Set<String>([
        "buildExpression(_:)",
        "buildOptional(_:)",
        "buildEither(first:)",
        "buildEither(second:)",
        "buildArray(_:)",
        "buildBlock(_:)",
        "buildFinalResult(_:)",
        "buildLimitedAvailability(_:)",
    ])

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        for decl in graph.declarations(ofKinds: Declaration.Kind.toplevelAttributableKind) {
            if decl.attributes.contains("resultBuilder") {
                for childDecl in decl.declarations {
                    if let name = childDecl.name, resultBuilderMethods.contains(name) {
                        graph.markRetained(childDecl)
                    }
                }
            }
        }
    }
}
