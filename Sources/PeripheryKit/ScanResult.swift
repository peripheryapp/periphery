import Foundation

public struct ScanResult: Codable, Hashable {
    enum Annotation: Codable, Hashable {
        case unused
        case assignOnlyProperty
        case redundantProtocol(references: Set<Reference>, inherited: Set<String>)
        case redundantPublicAccessibility(modules: Set<String>)

        enum CodingKeys: CodingKey {
            case unused
            case assignOnlyProperty
            case redundantProtocol
            case redundantPublicAccessibility
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let key = container.allKeys.first

            switch key {
            case .unused:
                self = .unused
            case .assignOnlyProperty:
                self = .assignOnlyProperty
            case .redundantProtocol:
                var nestedContainer = try container.nestedUnkeyedContainer(forKey: .redundantProtocol)
                let references = Set(try nestedContainer.decode([Reference].self))
                let inherited = Set(try nestedContainer.decode([String].self))
                self = .redundantProtocol(references: references, inherited: inherited)
            case .redundantPublicAccessibility:
                let modules = Set(try container.decode([String].self, forKey: .redundantPublicAccessibility))
                self = .redundantPublicAccessibility(modules: modules)
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unabled to decode enum.")
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .unused:
                try container.encode(true, forKey: .unused)
            case .assignOnlyProperty:
                try container.encode(true, forKey: .assignOnlyProperty)
            case .redundantProtocol(let references, let inherited):
                var nestedContainer = container.nestedUnkeyedContainer(forKey: .redundantProtocol)
                try nestedContainer.encode(Array(references).sorted())
                try nestedContainer.encode(Array(inherited).sorted())
            case .redundantPublicAccessibility(let modules):
                try container.encode(Array(modules).sorted(), forKey: .redundantPublicAccessibility)
            }
        }
    }

    let declaration: Declaration
    let annotation: Annotation
}
