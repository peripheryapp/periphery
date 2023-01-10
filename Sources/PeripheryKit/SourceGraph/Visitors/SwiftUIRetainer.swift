import Foundation
import Shared

final class SwiftUIRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private static let specialProtocolNames = ["PreviewProvider", "LibraryContentProvider"]
    private static let applicationDelegateAdaptorStructNames = ["UIApplicationDelegateAdaptor", "NSApplicationDelegateAdaptor"]

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        retainSpecialProtocolConformances()
        retainApplicationDelegateAdaptors()
    }

    // MARK: - Private

    private func retainSpecialProtocolConformances() {
        graph
            .declarations(ofKinds: [.class, .struct, .enum])
            .lazy
            .filter {
                $0.related.contains {
                    self.graph.isExternal($0) && $0.kind == .protocol && Self.specialProtocolNames.contains($0.name ?? "")
                }
            }
            .forEach { graph.markRetained($0) }
    }

    private func retainApplicationDelegateAdaptors() {
        graph
            .mainAttributedDeclarations
            .lazy
            .flatMap { $0.declarations }
            .filter { $0.kind == .varInstance }
            .filter {
                $0.references.contains {
                    ($0.kind == .struct || $0.kind == .enum) && Self.applicationDelegateAdaptorStructNames.contains($0.name ?? "")
                }
            }
            .forEach { graph.markRetained($0) }
    }
}
