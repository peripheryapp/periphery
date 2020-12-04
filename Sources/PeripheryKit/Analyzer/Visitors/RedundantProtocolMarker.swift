import Foundation

/// A protocol is considered redundant when it's never used as an existential type, despite being conformed to.
final class RedundantProtocolMarker: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() throws {
        let unreachableDeclarations = graph.unreachableDeclarations
        let protocolDecls = graph.declarations(ofKind: .protocol)

        for protocolDecl in protocolDecls {
            // Ensure the protocol doesn't inherit an external protocol.
            // The foreign protool may be used only by external code which is not visibile to us.
            // E.g a protocol may inherit Comparable and implement the operator '<', however we have no way to see
            // that '<' is used when calling sort().
            let inheritsForeignProtocol = graph
                .superclassReferences(of: protocolDecl)
                .filter { !($0.kind == .typealias && $0.name == "AnyObject") }
                .contains {
                    graph.explicitDeclaration(withUsr: $0.usr) == nil
                }

            guard !inheritsForeignProtocol else { continue }

            // Ensure the protocol isn't just simply unused.
            guard !unreachableDeclarations.contains(protocolDecl) else { continue }

            // Ensure all members are unused.
            guard protocolDecl.declarations.allSatisfy({ unreachableDeclarations.contains($0) }) else { continue }

            // Ensure the protocol is only used in a conformance.
            let protocolRefs = graph.references(to: protocolDecl)

            let allRefsAreConformances = protocolRefs.allSatisfy({
                guard
                    $0.isRelated,
                    let parentDecl = $0.parent as? Declaration
                else { return false }
                return parentDecl.kind.isConformingKind
            })

            if allRefsAreConformances {
                // The protocol is redundant.
                protocolDecl.analyzerHint = .redundantProtocol(references: protocolRefs)
                graph.markRedundant(protocolDecl)
                protocolDecl.declarations.forEach { graph.markIgnored($0) }
            }
        }
    }
}
