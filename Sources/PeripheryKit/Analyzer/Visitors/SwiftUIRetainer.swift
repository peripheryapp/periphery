import Foundation

final class SwiftUIRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        retainPreviewProviders()
    }

    // MARK: - Private

    private func retainPreviewProviders() {
        graph
            .declarations(ofKinds: [.class, .struct])
            .filter {
                $0.related.contains {
                    let isExternal = graph.explicitDeclaration(withUsr: $0.usr) == nil
                    return $0.kind == .protocol && $0.name == "PreviewProvider" && isExternal
                }
            }
            .forEach { decl in
                decl.markRetained(reason: .swiftUIPreviewProvider)
            }
    }
}
