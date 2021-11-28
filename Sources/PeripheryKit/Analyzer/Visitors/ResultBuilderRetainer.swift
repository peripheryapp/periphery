import Foundation

/// Retains static methods used by the Result Builder language feature.
final class ResultBuilderRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph
    private let resultBuilderMethods = Set<String>([
        "buildExpression(_:)",
        "buildOptional(_:)",
        "buildEither(first:)",
        "buildEither(second:)",
        "buildArray(_:)",
        "buildBlock(_:)"
    ])

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
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
