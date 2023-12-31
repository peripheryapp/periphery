import Foundation
import Shared

/// Builds a reference from a `Codable` conforming type to any child enum that conforms to `CodingKey`.
final class CodingKeyEnumReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph
    private let configuration: Configuration

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
        self.configuration = configuration
    }

    func mutate() {
        for enumDeclaration in graph.declarations(ofKind: .enum) {
            guard let parent = enumDeclaration.parent else { continue }

            let isCodingKey = graph.inheritedTypeReferences(of: enumDeclaration).contains {
                $0.kind == .protocol && $0.name == "CodingKey"
            }

            let codableTypes = ["Codable", "Decodable", "Encodable"] + configuration.externalEncodableProtocols + configuration.externalCodableProtocols

            let isParentCodable = graph.inheritedTypeReferences(of: parent).contains {
                guard let name = $0.name else { return false }
                return [.protocol, .typealias].contains($0.kind) && codableTypes.contains(name)
            }

            guard isCodingKey else { continue }

            // Retain each enum element.
            for elem in enumDeclaration.declarations {
                guard elem.kind == .enumelement else { continue }
                graph.markRetained(elem)
            }

            if isParentCodable {
                // Build a reference from the Codable type to the CodingKey enum.
                for usr in enumDeclaration.usrs {
                    let newReference = Reference(kind: .enum, usr: usr, location: enumDeclaration.location)
                    newReference.name = enumDeclaration.name
                    newReference.parent = parent
                    graph.add(newReference, from: parent)
                }
            }
        }
    }
}
