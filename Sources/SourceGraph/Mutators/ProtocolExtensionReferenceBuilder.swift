import Foundation
import Shared

final class ProtocolExtensionReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
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
            }
        }
    }
}
