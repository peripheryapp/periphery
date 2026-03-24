public final class Reference {
    // Explicit Hashable/Equatable using integer ordinals instead of the default
    // RawRepresentable conformance, which hashes/compares the String raw value.
    public enum Kind: String, Hashable, Equatable {
        case normal
        case related
        case retained

        @usableFromInline var ordinal: Int {
            switch self {
            case .normal: 0
            case .related: 1
            case .retained: 2
            }
        }

        @inlinable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(ordinal)
        }

        @inlinable
        public static func == (lhs: Kind, rhs: Kind) -> Bool {
            lhs.ordinal == rhs.ordinal
        }
    }

    // See Kind above for rationale on ordinal-based hashing/equality.
    public enum Role: String, Hashable, Equatable {
        case varType
        case returnType
        case parameterType
        case throwType
        case genericParameterType
        case genericRequirementType
        case inheritedType
        case refinedProtocolType
        case conformedType
        case initializerType
        case variableInitFunctionCall
        case functionCallMetatypeArgument
        case unknown

        @usableFromInline var ordinal: Int {
            switch self {
            case .varType: 0
            case .returnType: 1
            case .parameterType: 2
            case .throwType: 3
            case .genericParameterType: 4
            case .genericRequirementType: 5
            case .inheritedType: 6
            case .refinedProtocolType: 7
            case .conformedType: 8
            case .initializerType: 9
            case .variableInitFunctionCall: 10
            case .functionCallMetatypeArgument: 11
            case .unknown: 12
            }
        }

        @inlinable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(ordinal)
        }

        @inlinable
        public static func == (lhs: Role, rhs: Role) -> Bool {
            lhs.ordinal == rhs.ordinal
        }

        var isPubliclyExposable: Bool {
            switch self {
            case .varType, .returnType, .parameterType, .throwType, .genericParameterType, .genericRequirementType, .inheritedType, .refinedProtocolType, .initializerType, .variableInitFunctionCall, .functionCallMetatypeArgument:
                true
            default:
                false
            }
        }
    }

    public let location: Location
    public let kind: Kind
    public let declarationKind: Declaration.Kind
    public let name: String
    public var parent: Declaration?
    public var references: Set<Reference> = []
    public let usr: String
    public let usrID: USRID
    public var role: Role = .unknown

    private let hashValueCache: Int

    public init(
        name: String,
        kind: Kind,
        declarationKind: Declaration.Kind,
        usrID: USRID,
        usr: String,
        location: Location
    ) {
        self.name = name
        self.kind = kind
        self.declarationKind = declarationKind
        self.usrID = usrID
        self.usr = usr
        self.location = location
        var hasher = Hasher()
        hasher.combine(usrID)
        hasher.combine(location)
        hasher.combine(kind)
        hashValueCache = hasher.finalize()
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
        lhs.usrID == rhs.usrID && lhs.kind == rhs.kind && lhs.location == rhs.location
    }
}

extension Reference: CustomStringConvertible {
    public var description: String {
        "Reference(\(descriptionParts.joined(separator: ", ")))"
    }

    var descriptionParts: [String] {
        let formattedName = "'\(name)'"

        return [kind.rawValue, declarationKind.rawValue, formattedName, "'\(usr)'", role.rawValue, location.shortDescription]
    }
}

extension Reference: Comparable {
    public static func < (lhs: Reference, rhs: Reference) -> Bool {
        (lhs.location, lhs.usr) < (rhs.location, rhs.usr)
    }
}
