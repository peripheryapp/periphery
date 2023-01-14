import Foundation
import Shared

/// Builds a reference from a `Codable` conforming type to any child enum that conforms to `CodingKey`.
final class CodingKeyEnumReferenceBuilder: SourceGraphMutator {
    private let graph: SourceGraph

    required init(graph: SourceGraph, configuration: Configuration) {
        self.graph = graph
    }

    func mutate() {
        for enumDeclaration in graph.declarations(ofKind: .enum) {
            guard let parent = enumDeclaration.parent else { continue }

            let isCodingKey = graph.inheritedTypeReferences(of: enumDeclaration).contains {
                $0.kind == .protocol && $0.name == "CodingKey"
            }

            let isParentCodable = graph.inheritedTypeReferences(of: parent).contains {
                [.protocol, .typealias].contains($0.kind) && ["Codable", "Decodable", "Encodable"].contains($0.name)
            }

            if isCodingKey && isParentCodable {
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
