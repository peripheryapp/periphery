final class Reference {
    enum Role {
        case varType
        case returnType
        case parameterType
        case genericParameterType
        case genericRequirementType
        case inheritedType
        case refinedProtocolType
        case conformedType
        case initializerType
        case variableInitFunctionCall
        case functionCallMetatypeArgument
        case unknown

        var isPubliclyExposable: Bool {
            switch self {
            case .varType, .returnType, .parameterType, .genericParameterType, .genericRequirementType, .inheritedType, .refinedProtocolType, .initializerType, .variableInitFunctionCall, .functionCallMetatypeArgument:
                return true
            default:
                return false
            }
        }
    }

    let location: SourceLocation
    let kind: Declaration.Kind
    let isRelated: Bool
    var name: String?
    var parent: Declaration?
    var references: Set<Reference> = []
    let usr: String
    var role: Role = .unknown

    private let hashValueCache: Int

    init(kind: Declaration.Kind, usr: String, location: SourceLocation, isRelated: Bool = false) {
        self.kind = kind
        self.usr = usr
        self.isRelated = isRelated
        self.location = location
        self.hashValueCache = [usr.hashValue, location.hashValue, isRelated.hashValue].hashValue
    }

    var descendentReferences: Set<Reference> {
        references.flatMapSet { $0.descendentReferences }.union(references)
    }
}

extension Reference: Codable {
    enum CodingKeys: CodingKey {
        case location
        case kind
        case isRelated
        case usr
        case hashValueCache
    }
}

extension Reference: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(hashValueCache)
    }
}

extension Reference: Equatable {
    static func == (lhs: Reference, rhs: Reference) -> Bool {
        lhs.usr == rhs.usr && lhs.location == rhs.location && lhs.isRelated == rhs.isRelated
    }
}

extension Reference: CustomStringConvertible {
    var description: String {
        let referenceType = isRelated ? "Related" : "Reference"

        return "\(referenceType)(\(descriptionParts.joined(separator: ", ")))"
    }

    var descriptionParts: [String] {
        let formattedName = name != nil ? "'\(name!)'" : "nil"

        return [kind.rawValue, formattedName, "'\(usr)'", location.shortDescription]
    }
}

extension Reference: Comparable {
    static func < (lhs: Reference, rhs: Reference) -> Bool {
        lhs.location < rhs.location
    }
}
