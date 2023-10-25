public final class Reference {
    public enum Role {
        case varType
        case returnType
        case parameterType
        case genericParameterType
        case genericRequirementType
        case inheritedClassType
        case refinedProtocolType
        case variableInitFunctionCall
        case functionCallMetatypeArgument
        case unknown

        var isPubliclyExposable: Bool {
            switch self {
            case .varType, .returnType, .parameterType, .genericParameterType, .genericRequirementType, .inheritedClassType, .refinedProtocolType, .variableInitFunctionCall, .functionCallMetatypeArgument:
                return true
            default:
                return false
            }
        }
    }

    public let location: SourceLocation
    public let kind: Declaration.Kind
    public let isRelated: Bool
    public var name: String?
    public var parent: Declaration?
    public var references: Set<Reference> = []
    public let usr: String
    public var role: Role = .unknown

    private let identifier: Int

    init(kind: Declaration.Kind, usr: String, location: SourceLocation, isRelated: Bool = false) {
        self.kind = kind
        self.usr = usr
        self.isRelated = isRelated
        self.location = location
        self.identifier = [usr.hashValue, location.hashValue, isRelated.hashValue].hashValue
    }

    var descendentReferences: Set<Reference> {
        references.flatMapSet { $0.descendentReferences }.union(references)
    }
}

extension Reference: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

extension Reference: Equatable {
    public static func == (lhs: Reference, rhs: Reference) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension Reference: CustomStringConvertible {
    public var description: String {
        let referenceType = isRelated ? "Related" : "Reference"

        return "\(referenceType)(\(descriptionParts.joined(separator: ", ")))"
    }

    var descriptionParts: [String] {
        let formattedName = name != nil ? "'\(name!)'" : "nil"

        return [kind.rawValue, formattedName, "'\(usr)'", location.shortDescription]
    }
}

extension Reference: Comparable {
    public static func < (lhs: Reference, rhs: Reference) -> Bool {
        lhs.location < rhs.location
    }
}
