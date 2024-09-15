import Foundation
import Shared

/// A protocol is considered redundant when it's never used as an existential type, despite being conformed to.
final class RedundantProtocolMarker: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() throws {
        let unusedDeclarations = graph.unusedDeclarations
        let protocolDecls = graph.declarations(ofKind: .protocol)

        for protocolDecl in protocolDecls {
            // Ensure the protocol hasn't been been explicitly retained, e.g by a comment command.
            guard !graph.isRetained(protocolDecl) else { continue }

            // Ensure the protocol doesn't inherit an external protocol.
            // The foreign protocol may be used only by external code which is not visible to us.
            // E.g a protocol may inherit Comparable and implement the operator '<', however we have no way to see
            // that '<' is used when calling sort().
            let inheritsForeignProtocol = graph
                .inheritedTypeReferences(of: protocolDecl)
                .filter { !($0.kind == .typealias && $0.name == "AnyObject") }
                .contains { graph.isExternal($0) }

            guard !inheritsForeignProtocol else { continue }

            // Ensure all members implemented only in extensions are unused.
            let areAllExtensionsMembersUnused = protocolDecl
                .references
                .lazy
                .filter { $0.kind == .extensionProtocol }
                .compactMap { self.graph.explicitDeclaration(withUsr: $0.usr) }
                .flatMap(\.declarations)
                .allSatisfy { unusedDeclarations.contains($0) }

            guard areAllExtensionsMembersUnused else { continue }

            // Ensure the protocol isn't just simply unused.
            guard !unusedDeclarations.contains(protocolDecl) else { continue }

            // Ensure all members are unused.
            guard protocolDecl.declarations.allSatisfy({ unusedDeclarations.contains($0) }) else { continue }

            // Ensure the protocol is only used in a conformance.
            let protocolReferences = graph.references(to: protocolDecl)

            let areAllReferencesConformances = protocolReferences.allSatisfy { reference in
                guard reference.isRelated, let parent = reference.parent else {
                    return false
                }

                return parent.kind.isConformableKind
            }

            if areAllReferencesConformances {
                // The protocol is redundant.
                let inherited = graph.inheritedTypeReferences(of: protocolDecl).filter { $0.kind == .protocol }
                graph.markRedundantProtocol(protocolDecl, references: protocolReferences, inherited: inherited)
                protocolDecl.declarations.forEach { graph.markIgnored($0) }
            }
        }
    }
}
