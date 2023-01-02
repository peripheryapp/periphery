import Foundation

final class SwiftUIRetainer: SourceGraphMutator {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private static let specialProtocolNames = ["PreviewProvider", "LibraryContentProvider"]
    private static let applicationDelegateAdaptorStructNames = ["UIApplicationDelegateAdaptor", "NSApplicationDelegateAdaptor"]

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func mutate() {
        retainSpecialProtocolConformances()
        retanApplicationDelegateAdaptors()
    }

    // MARK: - Private

    private func retainSpecialProtocolConformances() {
        graph
            .declarations(ofKinds: [.class, .struct])
            .lazy
            .filter {
                $0.related.contains {
                    self.graph.isExternal($0) && $0.kind == .protocol && Self.specialProtocolNames.contains($0.name ?? "")
                }
            }
            .forEach { graph.markRetained($0) }
    }

    private func retanApplicationDelegateAdaptors() {
        graph
            .mainAttributedDeclarations
            .lazy
            .flatMap { $0.declarations }
            .filter { $0.kind == .varInstance }
            .filter {
                $0.references.contains {
                    $0.kind == .struct && Self.applicationDelegateAdaptorStructNames.contains($0.name ?? "")
                }
            }
            .forEach { graph.markRetained($0) }
    }
}
