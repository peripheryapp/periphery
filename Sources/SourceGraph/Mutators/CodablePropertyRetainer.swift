import Foundation
import Shared

final class CodablePropertyRetainer: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        if configuration.retainCodableProperties {
            for decl in graph.declarations(ofKinds: Declaration.Kind.discreteConformableKinds) {
                guard graph.isCodable(decl) else { continue }

                for decl in decl.declarations {
                    guard decl.kind == .varInstance else { continue }
                    graph.markRetained(decl)
                }
            }
        } else if configuration.retainEncodableProperties {
            for decl in graph.declarations(ofKinds: Declaration.Kind.discreteConformableKinds) {
                guard graph.isEncodable(decl) else { continue }

                for decl in decl.declarations {
                    guard decl.kind == .varInstance else { continue }
                    graph.markRetained(decl)
                }
            }
        }
    }
}
