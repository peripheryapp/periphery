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
                for usr in extensionDeclaration.usrs {
                    let reference = Reference(kind: .extensionProtocol, usr: usr, location: extendedProtocol.location)
                    reference.name = extendedProtocol.name
                    reference.parent = extendedProtocol
                    graph.add(reference, from: extendedProtocol)
                }

                // Now remove the reference from the extension to the protocol
                for reference in extensionDeclaration.references.filter({ extendedProtocol.usrs.contains($0.usr) }) {
                    graph.remove(reference)
                }

                // Now create a reference to the protocol and extension from any declaration in a
                // conforming class/struct with a matching default implementation in the
                // extension.
                for memberDeclaration in extensionDeclaration.declarations {
                    for reference in graph.references(to: memberDeclaration) {
                        if let parentDeclaration = reference.parent {
                            for usr in extensionDeclaration.usrs {
                                let extensionReference = Reference(kind: .extensionProtocol, usr: usr, location: reference.location)
                                extensionReference.name = extensionDeclaration.name
                                extensionReference.parent = parentDeclaration
                                graph.add(extensionReference, from: parentDeclaration)
                            }

                            for usr in extendedProtocol.usrs {
                                let protocolReference = Reference(kind: .protocol, usr: usr, location: reference.location)
                                protocolReference.name = extendedProtocol.name
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
        let constrainingProtocolRefs = extensionDeclaration.references.filter { $0.role == .genericRequirementType && $0.kind == .protocol }

        for constrainingProtocolRef in constrainingProtocolRefs {
            guard let constrainingProtocol = graph.declaration(withUsr: constrainingProtocolRef.usr) else { continue }

            // For each member declared in the extension, check if it satisfies a requirement of the constraining protocol
            for memberDeclaration in extensionDeclaration.declarations {
                // Find matching requirement in the constraining protocol
                let matchingRequirement = constrainingProtocol.declarations.first {
                    $0.kind == memberDeclaration.kind && $0.name == memberDeclaration.name
                }

                guard let matchingRequirement else { continue }

                // Create a related reference from the extension's member to the protocol requirement.
                // This mimics the structure of a normal protocol conformance, where the conforming
                // declaration has a related reference to the protocol member it implements.
                // ProtocolConformanceReferenceBuilder will then invert this to create a reference
                // from the protocol requirement to the extension's implementation.
                for usr in matchingRequirement.usrs {
                    let relatedReference = Reference(
                        kind: matchingRequirement.kind,
                        usr: usr,
                        location: memberDeclaration.location,
                        isRelated: true,
                    )
                    relatedReference.name = matchingRequirement.name
                    relatedReference.parent = memberDeclaration
                    graph.add(relatedReference, from: memberDeclaration)
                }
            }
        }
    }
}
