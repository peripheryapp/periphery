public final class Reference {
    public enum Kind: String {
        case normal
        case related
        case retained
    }

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
    public let kind: Kind
    public let declarationKind: Declaration.Kind
    public var name: String?
    public var parent: Declaration?
    public var references: Set<Reference> = []
    public let usr: String
    public var role: Role = .unknown

    private let hashValueCache: Int

    public init(
        kind: Kind,
        declarationKind: Declaration.Kind,
        usr: String,
        location: Location
    ) {
        self.kind = kind
        self.declarationKind = declarationKind
        self.usr = usr
        self.location = location
        hashValueCache = [usr.hashValue, location.hashValue, kind.hashValue].hashValue
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
        lhs.usr == rhs.usr && lhs.location == rhs.location && lhs.kind == rhs.kind
    }
}

extension Reference: CustomStringConvertible {
    public var description: String {
        "Reference(\(descriptionParts.joined(separator: ", ")))"
    }

    var descriptionParts: [String] {
        let formattedName = name != nil ? "'\(name!)'" : "nil"

        return [kind.rawValue, declarationKind.rawValue, formattedName, "'\(usr)'", role.rawValue, location.shortDescription]
    }
}

extension Reference: Comparable {
    public static func < (lhs: Reference, rhs: Reference) -> Bool {
        if lhs.location == rhs.location {
            return lhs.usr < rhs.usr
        }
        return lhs.location < rhs.location
    }
}
