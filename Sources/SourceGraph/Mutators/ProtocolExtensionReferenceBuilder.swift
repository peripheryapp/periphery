import Configuration
import Foundation
import Shared

/// Builds references between protocols and their extensions.
///
/// This mutator handles:
/// 1. Creating references from protocols to their extensions
/// 2. Creating references from conforming types to protocol extensions when they use default implementations
/// 3. Constrained protocol extensions (e.g., `extension ProtocolA where Self: ProtocolB`) where the extension
///    provides default implementations that satisfy requirements of the constraining protocol
final class ProtocolExtensionReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration _: Configuration, swiftVersion _: SwiftVersion) {
        self.graph = graph
    }

    func mutate() throws {
        for extensionDeclaration in graph.declarations(ofKind: .extensionProtocol) {
            // First, create a reference from each protocol to the extension.
            if let extendedProtocol = try graph.extendedDeclaration(forExtension: extensionDeclaration) {
                for usrID in extensionDeclaration.usrIDs {
                    let usr = graph.usrInterner.string(for: usrID)
                    let reference = Reference(
                        name: extendedProtocol.name,
                        kind: .normal,
                        declarationKind: .extensionProtocol,
                        usrID: usrID,
                        usr: usr,
                        location: extendedProtocol.location
                    )
                    reference.parent = extendedProtocol
                    graph.add(reference, from: extendedProtocol)
                }

                let extendedProtocolUsrIDs = Set(extendedProtocol.usrIDs)
                for reference in extensionDeclaration.references.filter({ extendedProtocolUsrIDs.contains($0.usrID) }) {
                    graph.remove(reference)
                }

                // Now create a reference to the protocol and extension from any declaration in a
                // conforming class/struct with a matching default implementation in the
                // extension.
                for memberDeclaration in extensionDeclaration.declarations {
                    for reference in graph.references(to: memberDeclaration) {
                        if let parentDeclaration = reference.parent {
                            for usrID in extensionDeclaration.usrIDs {
                                let usr = graph.usrInterner.string(for: usrID)
                                let extensionReference = Reference(
                                    name: extensionDeclaration.name,
                                    kind: .normal,
                                    declarationKind: .extensionProtocol,
                                    usrID: usrID,
                                    usr: usr,
                                    location: reference.location
                                )
                                extensionReference.parent = parentDeclaration
                                graph.add(extensionReference, from: parentDeclaration)
                            }

                            for usrID in extendedProtocol.usrIDs {
                                let usr = graph.usrInterner.string(for: usrID)
                                let protocolReference = Reference(
                                    name: extendedProtocol.name,
                                    kind: .normal,
                                    declarationKind: .protocol,
                                    usrID: usrID,
                                    usr: usr,
                                    location: reference.location
                                )
                                protocolReference.parent = parentDeclaration
                                graph.add(protocolReference, from: parentDeclaration)
                            }
                        }
                    }
                }

                // Handle constrained protocol extensions (e.g., `extension ProtocolA where Self: ProtocolB`).
                // When the extension provides default implementations for members required by ProtocolB,
                // create references from ProtocolB's requirements to the extension's implementations.
                try referenceConstrainedExtensionImplementations(extensionDeclaration: extensionDeclaration)
            }
        }
    }

    /// For constrained protocol extensions like `extension ProtocolA where Self: ProtocolB`,
    /// the extension's members may satisfy requirements of the constraining protocol (ProtocolB).
    /// This method creates the necessary related references so that the conformance is properly recognized.
    ///
    /// The related reference is added from the extension's member to the protocol requirement,
    /// which will then be inverted by ProtocolConformanceReferenceBuilder.
    private func referenceConstrainedExtensionImplementations(extensionDeclaration: Declaration) throws {
        // Find all protocols this extension is constrained by (via `where Self: ProtocolName`)
        let constrainingProtocolRefs = extensionDeclaration.references.filter { $0.role == .genericRequirementType && $0.declarationKind == .protocol }

        for constrainingProtocolRef in constrainingProtocolRefs {
            guard let constrainingProtocol = graph.declaration(withUsrID: constrainingProtocolRef.usrID) else { continue }

            // For each member declared in the extension, check if it satisfies a requirement of the constraining protocol
            for memberDeclaration in extensionDeclaration.declarations {
                // Find matching requirement in the constraining protocol
                let matchingRequirement = constrainingProtocol.declarations
                    .filter { $0.kind == memberDeclaration.kind && $0.name == memberDeclaration.name }
                    .min()

                guard let matchingRequirement else { continue }

                // Create a related reference from the extension's member to the protocol requirement.
                // This mimics the structure of a normal protocol conformance, where the conforming
                // declaration has a related reference to the protocol member it implements.
                // ProtocolConformanceReferenceBuilder will then invert this to create a reference
                // from the protocol requirement to the extension's implementation.
                for usrID in matchingRequirement.usrIDs {
                    let usr = graph.usrInterner.string(for: usrID)
                    let relatedReference = Reference(
                        name: matchingRequirement.name,
                        kind: .related,
                        declarationKind: matchingRequirement.kind,
                        usrID: usrID,
                        usr: usr,
                        location: memberDeclaration.location
                    )
                    relatedReference.parent = memberDeclaration
                    graph.add(relatedReference, from: memberDeclaration)
                }
            }
        }
    }
}
