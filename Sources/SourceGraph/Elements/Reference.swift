public final class Reference {
    public enum Role: String {
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
                true
            default:
                false
            }
        }
    }

    public let location: Location
    public let kind: Declaration.Kind
    public let isRelated: Bool
    public var name: String?
    public var parent: Declaration?
    public var references: Set<Reference> = []
    public let usr: String
    public var role: Role = .unknown

    private let hashValueCache: Int

    public init(kind: Declaration.Kind, usr: String, location: Location, isRelated: Bool = false) {
        self.kind = kind
        self.usr = usr
        self.isRelated = isRelated
        self.location = location
        hashValueCache = [usr.hashValue, location.hashValue, isRelated.hashValue].hashValue
    }

    var descendentReferences: Set<Reference> {
        references.flatMapSet { $0.descendentReferences }.union(references)
    }
}

extension Reference: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValueCache)
    }
}

extension Reference: Equatable {
    public static func == (lhs: Reference, rhs: Reference) -> Bool {
        lhs.usr == rhs.usr && lhs.location == rhs.location && lhs.isRelated == rhs.isRelated
    }
}

extension Reference: CustomStringConvertible {
    public var description: String {
        let referenceType = isRelated ? "Related" : "Reference"

        return "\(referenceType)(\(descriptionParts.joined(separator: ", ")))"
    }

    private var descriptionParts: [String] {
        let formattedName = name != nil ? "'\(name!)'" : "nil"

        return [kind.rawValue, formattedName, "'\(usr)'", role.rawValue, location.shortDescription]
    }
}

extension Reference: Comparable {
    public static func < (lhs: Reference, rhs: Reference) -> Bool {
        lhs.location < rhs.location
    }
}
