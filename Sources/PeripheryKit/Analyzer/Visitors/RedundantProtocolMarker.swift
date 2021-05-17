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

            // Ensure all members implemented only in extensions are unused.
            let areAllExtensionsMembersUnused = protocolDecl
                .references
                .lazy
                .filter { $0.kind == .extensionProtocol }
                .compactMap { self.graph.explicitDeclaration(withUsr: $0.usr) }
                .flatMap { $0.declarations }
                .allSatisfy({ unreachableDeclarations.contains($0) })

            guard areAllExtensionsMembersUnused else { continue }

            // Ensure the protocol isn't just simply unused.
            guard !unreachableDeclarations.contains(protocolDecl) else { continue }

            // Ensure all members are unused.
            guard protocolDecl.declarations.allSatisfy({ unreachableDeclarations.contains($0) }) else { continue }

            // Ensure the protocol is only used in a conformance.
            let protocolReferences = graph.references(to: protocolDecl)

            let areAllReferencesConformances = protocolReferences.allSatisfy { reference in
                guard reference.isRelated, let parent = reference.parent else {
                    return false
                }

                return parent.kind.isConformingKind
            }

            if areAllReferencesConformances {
                // The protocol is redundant.
                protocolDecl.analyzerHint = .redundantProtocol(references: protocolReferences)
                graph.markRedundant(protocolDecl)
                protocolDecl.declarations.forEach { graph.markIgnored($0) }
            }
        }
    }
}
