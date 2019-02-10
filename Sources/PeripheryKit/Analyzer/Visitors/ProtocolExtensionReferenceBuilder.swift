import Foundation

class ProtocolExtensionReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() throws {
        for extensionDeclaration in graph.declarations(ofKind: .extensionProtocol) {
            // First, create a reference from each protocol to the extension.
            if let extendedProtocol = try graph.extendedDeclaration(forExtension: extensionDeclaration) {
                let reference = Reference(kind: .extensionProtocol, usr: extensionDeclaration.usr, location: extendedProtocol.location)
                reference.name = extendedProtocol.name
                reference.parent = extendedProtocol
                graph.add(reference, from: extendedProtocol)

                // Now remove the reference from the extension to the protocol
                for reference in extensionDeclaration.references.filter({ $0.usr == extendedProtocol.usr  }) {
                    graph.remove(reference)
                }

                // Now create a reference to the protocol and extension from any declaration in a
                // conforming class/struct with a matching default implementation in the
                // extension.
                for memberDeclaration in extensionDeclaration.declarations {
                    for reference in graph.references(toUsr: memberDeclaration.usr) {
                        if let parentDeclaration = reference.ancestralDeclaration {
                            let extensionReference = Reference(kind: .extensionProtocol, usr: extensionDeclaration.usr, location: reference.location)
                            extensionReference.name = extensionDeclaration.name
                            extensionReference.parent = parentDeclaration
                            graph.add(extensionReference, from: parentDeclaration)

                            let protocolReference = Reference(kind: .protocol, usr: extendedProtocol.usr, location: reference.location)
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
