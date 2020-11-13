import Foundation

final class SwiftUIRetainer: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph
    private let specialProtocols = ["PreviewProvider", "LibraryContentProvider"]

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        retainSpecialProtocolConformances()
    }

    // MARK: - Private

    private func retainSpecialProtocolConformances() {
        graph
            .declarations(ofKinds: [.class, .struct])
            .filter {
                $0.related.contains {
                    let isExternal = graph.explicitDeclaration(withUsr: $0.usr) == nil
                    return isExternal && $0.kind == .protocol && specialProtocols.contains($0.name ?? "")
                }
            }
            .forEach { decl in
                decl.markRetained()
            }
    }
}
