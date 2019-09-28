import Foundation

final class PlainExtensionEliminator: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        // TODO: explain

        let plainExtensions = graph.rootDeclarations.filter {
            $0.kind == .extensionClass &&
                $0.related.isEmpty
        }

        for plainExtension in plainExtensions {
            let reference = plainExtension.references.first {
                // TODO: review
                $0.kind == .class &&
                    $0.location == plainExtension.location &&
                    $0.name == plainExtension.name
            }

            if let reference = reference {
                graph.remove(reference)
            }
        }
    }
}
