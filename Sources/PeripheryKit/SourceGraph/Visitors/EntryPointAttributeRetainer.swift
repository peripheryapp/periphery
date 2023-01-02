import Foundation

final class EntryPointAttributeRetainer: SourceGraphMutator {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func mutate() {
        graph
            .declarations(ofKinds: [.class, .struct])
            .lazy
            .filter {
                $0.attributes.contains("NSApplicationMain") ||
                $0.attributes.contains("UIApplicationMain") ||
                $0.attributes.contains("main")
            }
            .forEach {
                graph.markRetained($0)
                graph.markMainAttributed($0)

                $0.ancestralDeclarations.forEach {
                    graph.markRetained($0)
                }

                if $0.attributes.contains("main") {
                    // @main requires a static main() function.
                    $0.declarations
                        .filter { $0.kind == .functionMethodStatic && $0.name == "main()"}
                        .forEach { graph.markRetained($0) }
                }
            }
    }
}
