import Foundation
import Shared

final class EntryPointAttributeRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration) {
        self.graph = graph
    }

    func mutate() {
        graph
            .declarations(ofKinds: [.class, .struct, .enum])
            .lazy
            .filter {
                $0.attributes.contains("NSApplicationMain") ||
                    $0.attributes.contains("UIApplicationMain") ||
                    $0.attributes.contains("main")
            }
            .forEach {
                graph.markRetained($0)
                graph.markMainAttributed($0)

                for ancestralDeclaration in $0.ancestralDeclarations {
                    graph.markRetained(ancestralDeclaration)
                }

                if $0.attributes.contains("main") {
                    // @main requires a static main() function.
                    $0.declarations
                        .filter { $0.kind == .functionMethodStatic && $0.name == "main()" }
                        .forEach { graph.markRetained($0) }
                }
            }
    }
}
