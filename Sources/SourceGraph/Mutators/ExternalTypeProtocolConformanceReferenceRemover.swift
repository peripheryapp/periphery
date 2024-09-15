import Foundation
import Shared

final class ExternalTypeProtocolConformanceReferenceRemover: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() throws {
        let extensionDecls = graph.declarations(ofKinds: [.extensionClass, .extensionStruct, .extensionEnum])

        for extDecl in extensionDecls {
            // Ensure the extended type is external.
            guard try graph.extendedDeclaration(forExtension: extDecl) == nil else { continue }

            // Ensure the type is extended by local protocols.
            let protocolDecls = extDecl.related.filter { $0.kind == .protocol }.map { graph.explicitDeclaration(withUsr: $0.usr) }
            guard !protocolDecls.isEmpty else { continue }

            // Find all related references that may be protocol members.
            let relatedRefs = extDecl.related.filter(\.kind.isProtocolMemberKind)

            for relatedRef in relatedRefs {
                // Ensure the relatedDecl is a member of a protocol.
                guard
                    let relatedDecl = graph.explicitDeclaration(withUsr: relatedRef.usr),
                    let parentDecl = relatedDecl.parent,
                    protocolDecls.contains(parentDecl)
                else { continue }

                // Retain all parameters from the protocol declaration as altering the function signature would break
                // conformance.
                relatedDecl.unusedParameters.forEach { graph.markRetained($0) }

                // Remove the related reference.
                graph.remove(relatedRef)
            }
        }
    }
}
