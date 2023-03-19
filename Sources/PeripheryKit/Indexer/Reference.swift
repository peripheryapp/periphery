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

    public enum Kind: String {
        case `associatedtype` = "associatedtype"
        case `class` = "class"
        case `enum` = "enum"
        case enumelement = "enumelement"
        case `extension` = "extension"
        case extensionClass = "extension.class"
        case extensionEnum = "extension.enum"
        case extensionProtocol = "extension.protocol"
        case extensionStruct = "extension.struct"
        case functionAccessorAddress = "function.accessor.address"
        case functionAccessorDidset = "function.accessor.didset"
        case functionAccessorGetter = "function.accessor.getter"
        case functionAccessorMutableaddress = "function.accessor.mutableaddress"
        case functionAccessorSetter = "function.accessor.setter"
        case functionAccessorWillset = "function.accessor.willset"
        case functionConstructor = "function.constructor"
        case functionDestructor = "function.destructor"
        case functionFree = "function.free"
        case functionMethodClass = "function.method.class"
        case functionMethodInstance = "function.method.instance"
        case functionMethodStatic = "function.method.static"
        case functionOperator = "function.operator"
        case functionOperatorInfix = "function.operator.infix"
        case functionOperatorPostfix = "function.operator.postfix"
        case functionOperatorPrefix = "function.operator.prefix"
        case functionSubscript = "function.subscript"
        case genericTypeParam = "generic_type_param"
        case module = "module"
        case precedenceGroup = "precedencegroup"
        case `protocol` = "protocol"
        case `struct` = "struct"
        case `typealias` = "typealias"
        case varClass = "var.class"
        case varGlobal = "var.global"
        case varInstance = "var.instance"
        case varLocal = "var.local"
        case varParameter = "var.parameter"
        case varStatic = "var.static"

        static var protocolMemberKinds: [Kind] {
            let functionKinds: [Kind] = [.functionMethodInstance, .functionMethodStatic, .functionSubscript, .functionOperator, .functionOperatorInfix, .functionOperatorPostfix, .functionOperatorPrefix, .functionConstructor]
            let variableKinds: [Kind] = [.varInstance, .varStatic]
            return functionKinds + variableKinds
        }

        static var protocolMemberConformingKinds: [Kind] {
            // Protocols cannot declare 'class' members, yet classes can fulfill the requirement with either a 'class'
            // or 'static' member.
            protocolMemberKinds + [.varClass, .functionMethodClass, .associatedtype]
        }

        var isProtocolMemberKind: Bool {
            Self.protocolMemberKinds.contains(self)
        }

        var isProtocolMemberConformingKind: Bool {
            Self.protocolMemberConformingKinds.contains(self)
        }

        var isFunctionKind: Bool {
            rawValue.hasPrefix("function")
        }

        var declarationEquivalent: Declaration.Kind? {
            Declaration.Kind(rawValue: rawValue)
        }
    }

    public let location: SourceLocation
    public let kind: Kind
    public let isRelated: Bool
    public var name: String?
    public var parent: Declaration?
    public var references: Set<Reference> = []
    public let usr: String
    public var role: Role = .unknown

    private let identifier: String

    init(kind: Kind, usr: String, location: SourceLocation, isRelated: Bool = false) {
        self.kind = kind
        self.usr = usr
        self.isRelated = isRelated
        self.location = location
        self.identifier = "\(usr.hashValue)-\(location.hashValue)-\(isRelated.hashValue)"
    }

    var descendentReferences: Set<Reference> {
        Set(references.flatMap { $0.descendentReferences }).union(references)
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
