import Configuration
import Foundation
import Shared

final class EntryPointAttributeRetainer: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() {
        graph
            .declarations(ofKinds: [.class, .struct, .enum])
            .lazy
            .filter {
                $0.attributes.contains(where: { $0.name == "NSApplicationMain" }) ||
                    $0.attributes.contains(where: { $0.name == "UIApplicationMain" }) ||
                    $0.attributes.contains(where: { $0.name == "main" })
            }
            .forEach {
                graph.markRetained($0)
                graph.markMainAttributed($0)

                for ancestralDeclaration in $0.ancestralDeclarations {
                    graph.markRetained(ancestralDeclaration)
                }

                if $0.attributes.contains(where: { $0.name == "main" }) {
                    // @main requires a static main() function.
                    $0.declarations
                        .filter { $0.kind == .functionMethodStatic && $0.name == "main()" }
                        .forEach { graph.markRetained($0) }
                }
            }
    }
}
