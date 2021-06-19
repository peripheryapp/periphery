import Foundation

/// Builds a reference from a `Codable` conforming type to any child enum that conforms to `CodingKey`.
final class CodingKeyEnumReferenceBuilder: SourceGraphVisitor {
    static func make(graph: SourceGraph) -> Self {
        return self.init(graph: graph)
    }

    private let graph: SourceGraph

    required init(graph: SourceGraph) {
        self.graph = graph
    }

    func visit() {
        for enumDeclaration in graph.declarations(ofKind: .enum) {
            guard let parent = enumDeclaration.parent else { continue }

            let isCodingKey = graph.superclassReferences(of: enumDeclaration).contains {
                $0.kind == .protocol && $0.name == "CodingKey"
            }

            let isParentCodable = graph.superclassReferences(of: parent).contains {
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
