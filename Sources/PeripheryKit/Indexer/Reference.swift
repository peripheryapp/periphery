class Reference: Entity {
    enum Kind: String {
        case `associatedtype` = "source.lang.swift.ref.associatedtype"
        case `class` = "source.lang.swift.ref.class"
        case `enum` = "source.lang.swift.ref.enum"
        case enumelement = "source.lang.swift.ref.enumelement"
        case `extension` = "source.lang.swift.ref.extension"
        case extensionClass = "source.lang.swift.ref.extension.class"
        case extensionEnum = "source.lang.swift.ref.extension.enum"
        case extensionProtocol = "source.lang.swift.ref.extension.protocol"
        case extensionStruct = "source.lang.swift.ref.extension.struct"
        case functionAccessorAddress = "source.lang.swift.ref.function.accessor.address"
        case functionAccessorDidset = "source.lang.swift.ref.function.accessor.didset"
        case functionAccessorGetter = "source.lang.swift.ref.function.accessor.getter"
        case functionAccessorMutableaddress = "source.lang.swift.ref.function.accessor.mutableaddress"
        case functionAccessorSetter = "source.lang.swift.ref.function.accessor.setter"
        case functionAccessorWillset = "source.lang.swift.ref.function.accessor.willset"
        case functionConstructor = "source.lang.swift.ref.function.constructor"
        case functionDestructor = "source.lang.swift.ref.function.destructor"
        case functionFree = "source.lang.swift.ref.function.free"
        case functionMethodClass = "source.lang.swift.ref.function.method.class"
        case functionMethodInstance = "source.lang.swift.ref.function.method.instance"
        case functionMethodStatic = "source.lang.swift.ref.function.method.static"
        case functionOperator = "source.lang.swift.ref.function.operator"
        case functionOperatorInfix = "source.lang.swift.ref.function.operator.infix"
        case functionOperatorPostfix = "source.lang.swift.ref.function.operator.postfix"
        case functionOperatorPrefix = "source.lang.swift.ref.function.operator.prefix"
        case functionSubscript = "source.lang.swift.ref.function.subscript"
        case genericTypeParam = "source.lang.swift.ref.generic_type_param"
        case module = "source.lang.swift.ref.module"
        case precedenceGroup = "source.lang.swift.ref.precedencegroup"
        case `protocol` = "source.lang.swift.ref.protocol"
        case `struct` = "source.lang.swift.ref.struct"
        case `typealias` = "source.lang.swift.ref.typealias"
        case varClass = "source.lang.swift.ref.var.class"
        case varGlobal = "source.lang.swift.ref.var.global"
        case varInstance = "source.lang.swift.ref.var.instance"
        case varLocal = "source.lang.swift.ref.var.local"
        case varParameter = "source.lang.swift.ref.var.parameter"
        case varStatic = "source.lang.swift.ref.var.static"

        var isFunctionKind: Bool {
            return rawValue.hasPrefix("source.lang.swift.ref.function")
        }

        var shortName: String {
            let namespace = "source.lang.swift.ref"
            let index = rawValue.index(after: namespace.endIndex)

            return String(rawValue.suffix(from: index))
        }

        var declarationEquivalent: Declaration.Kind? {
            let value = rawValue.replacingOccurrences(of: ".ref.", with: ".decl.")
            return Declaration.Kind(rawValue: value)
        }
    }

    let location: SourceLocation
    let kind: Kind
    let usr: String

    var parent: Entity?
    var declarations: Set<Declaration> = []
    var references: Set<Reference> = []
    var receiverUsr: String?
    var name: String?
    var isRelated: Bool = false

    init(kind: Kind, usr: String, location: SourceLocation) {
        self.kind = kind
        self.usr = usr
        self.location = location
    }

    var descendentReferences: Set<Reference> {
        return Set(references.flatMap { $0.descendentReferences }).union(references)
    }

    var ancestralDeclaration: Declaration? {
        if let parent = parent as? Reference {
            return parent.ancestralDeclaration
        } else if let parent = parent as? Declaration {
            return parent
        }

        return nil
    }
}

extension Reference: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(usr)
        hasher.combine(location)
        hasher.combine(isRelated)

        if let receiverUsr = receiverUsr {
            hasher.combine(receiverUsr)
        }
    }
}

extension Reference: Equatable {
    static func == (lhs: Reference, rhs: Reference) -> Bool {
        let usrIsEqual = lhs.usr == rhs.usr
        let locationIsEqual = lhs.location == rhs.location
        let kindIsEqual = lhs.kind == rhs.kind
        let relatedIsEqual = lhs.isRelated == rhs.isRelated
        var receiverUsrIsEqual = true

        if let lhsReceiverUsr = lhs.receiverUsr,
            let rhsReceiverUsr = rhs.receiverUsr {
            receiverUsrIsEqual = lhsReceiverUsr == rhsReceiverUsr
        }

        return usrIsEqual && receiverUsrIsEqual && locationIsEqual && kindIsEqual && relatedIsEqual
    }
}

extension Reference: CustomStringConvertible {
    var description: String {
        let referenceType = isRelated ? "Related" : "Reference"

        return "\(referenceType)(\(descriptionParts.joined(separator: ", ")))"
    }

    var descriptionParts: [String] {
        let formattedReceiverUsr = receiverUsr != nil ? "'\(receiverUsr!)'" : "nil"
        let formattedName = name != nil ? "'\(name!)'" : "nil"

        return [kind.shortName, formattedName, "'\(usr)'", formattedReceiverUsr, location.shortDescription]
    }
}
