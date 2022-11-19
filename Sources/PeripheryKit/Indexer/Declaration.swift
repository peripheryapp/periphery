import Foundation

public final class Declaration {
    public enum Kind: String, RawRepresentable, CaseIterable {
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

        public static var functionKinds: Set<Kind> {
            Set(Kind.allCases.filter { $0.isFunctionKind })
        }

        var isFunctionKind: Bool {
            rawValue.hasPrefix("function")
        }

        static var variableKinds: Set<Kind> {
            Set(Kind.allCases.filter { $0.isVariableKind })
        }

        var isVariableKind: Bool {
            rawValue.hasPrefix("var")
        }

        static var globalKinds: Set<Kind> = [
            .class,
            .protocol,
            .enum,
            .struct,
            .typealias,
            .functionFree,
            .extensionClass,
            .extensionStruct,
            .extensionProtocol,
            .varGlobal
        ]

        static var extensionKinds: Set<Kind> {
            Set(Kind.allCases.filter { $0.isExtensionKind })
        }

        var extendedKind: Kind? {
            switch self {
            case .extensionClass:
                return .class
            case .extensionStruct:
                return .struct
            case .extensionEnum:
                return .enum
            case .extensionProtocol:
                return .protocol
            default:
                return nil
            }
        }

        var isExtensionKind: Bool {
            rawValue.hasPrefix("extension")
        }

        var isConformableKind: Bool {
            isDiscreteConformableKind || isExtensionKind
        }

        var isDiscreteConformableKind: Bool {
            Self.discreteConformableKinds.contains(self)
        }

        static var discreteConformableKinds: Set<Kind> {
            return [.class, .struct, .enum]
        }

        static var concreteTypeDeclarableKinds: Set<Kind> {
            return [.class, .struct, .enum, .typealias]
        }

        static var accessorKinds: Set<Kind> {
            Set(Kind.allCases.filter { $0.isAccessorKind })
        }

        static var accessibleKinds: Set<Kind> {
            functionKinds.union(variableKinds).union(globalKinds)
        }

        public var isAccessorKind: Bool {
            rawValue.hasPrefix("function.accessor")
        }

        static var toplevelAttributableKind: Set<Kind> {
            [.class, .struct, .enum]
        }

        public var displayName: String? {
            switch self {
            case .class:
                return "class"
            case .protocol:
                return "protocol"
            case .struct:
                return "struct"
            case .enum:
                return "enum"
            case .enumelement:
                return "enum case"
            case .typealias:
                return "typealias"
            case .associatedtype:
                return "associatedtype"
            case .functionConstructor:
                return "initializer"
            case .extension, .extensionEnum, .extensionClass, .extensionStruct, .extensionProtocol:
                return "extension"
            case .functionMethodClass, .functionMethodStatic, .functionMethodInstance, .functionFree, .functionOperator, .functionSubscript:
                return "function"
            case .varStatic, .varInstance, .varClass, .varGlobal, .varLocal:
                return "property"
            case .varParameter:
                return "parameter"
            case .genericTypeParam:
                return "generic type parameter"
            default:
                return nil
            }
        }

        var referenceEquivalent: Reference.Kind? {
            Reference.Kind(rawValue: rawValue)
        }
    }

    public let location: SourceLocation
    public var attributes: Set<String> = []
    public var modifiers: Set<String> = []
    public var accessibility: DeclarationAccessibility = .init(value: .internal, isExplicit: false)
    public let kind: Kind
    public var name: String?
    public let usrs: Set<String>
    public var unusedParameters: Set<Declaration> = []
    public var declarations: Set<Declaration> = []
    public var commentCommands: Set<CommentCommand> = []
    public var references: Set<Reference> = []
    public var declaredType: String?
    public var ifLetShorthandIdentifiers: Set<String> = []

    public var parent: Declaration?
    var related: Set<Reference> = []
    var isImplicit: Bool = false
    var isObjcAccessible: Bool = false

    var ancestralDeclarations: Set<Declaration> {
        var maybeParent = parent
        var declarations: Set<Declaration> = []

        while let thisParent = maybeParent {
            declarations.insert(thisParent)
            maybeParent = thisParent.parent
        }

        return declarations
    }

    public var descendentDeclarations: Set<Declaration> {
        Set(declarations.flatMap { $0.descendentDeclarations }).union(declarations).union(unusedParameters)
    }

    var immediateInheritedTypeReferences: Set<Reference> {
        let superclassReferences = related.filter { [.class, .struct, .protocol].contains($0.kind) }

        // Inherited typealiases are References instead of a Related.
        let typealiasReferences = references.filter { $0.kind == .typealias }
        return superclassReferences.union(typealiasReferences)
    }

    var isComplexProperty: Bool {
        return declarations.contains {
            if [.functionAccessorWillset,
                .functionAccessorDidset].contains($0.kind) {
                return true
            }

            if $0.kind.isAccessorKind && !$0.references.isEmpty {
                return true
            }

            return false
        }
    }

    init(kind: Kind, usrs: Set<String>, location: SourceLocation) {
        self.kind = kind
        self.usrs = usrs
        self.location = location
    }

    func isDeclaredInExtension(kind: Declaration.Kind) -> Bool {
        guard let parent = parent else { return false }
        return parent.kind == kind
    }
}

extension Declaration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(usrs)
    }
}

extension Declaration: Equatable {
    public static func == (lhs: Declaration, rhs: Declaration) -> Bool {
        lhs.usrs == rhs.usrs
    }
}

extension Declaration: CustomStringConvertible {
    public var description: String {
        "Declaration(\(descriptionParts.joined(separator: ", ")))"
    }

    private var descriptionParts: [String] {
        let formattedName = name != nil ? "'\(name!)'" : "nil"
        let formattedAttributes = "[" + attributes.sorted().joined(separator: ", ") + "]"
        let formattedModifiers = "[" + modifiers.sorted().joined(separator: ", ") + "]"
        let formattedCommentCommands = "[" + commentCommands.map { $0.description }.sorted().joined(separator: ", ") + "]"
        let formattedUsrs = "[" + usrs.sorted().joined(separator: ", ") + "]"
        let implicitOrExplicit = isImplicit ? "implicit" : "explicit"
        return [kind.rawValue,
                formattedName,
                implicitOrExplicit,
                accessibility.value.rawValue,
                formattedModifiers,
                formattedAttributes,
                formattedCommentCommands,
                formattedUsrs,
                location.shortDescription]
    }
}

extension Declaration: Comparable {
    public static func < (lhs: Declaration, rhs: Declaration) -> Bool {
        if lhs.location == rhs.location {
            return lhs.usrs.sorted().joined() < rhs.usrs.sorted().joined()
        }

        return lhs.location < rhs.location
    }
}

public struct DeclarationAccessibility {
    public let value: Accessibility
    public let isExplicit: Bool

    public func isExplicitly(_ testValue: Accessibility) -> Bool {
        isExplicit && value == testValue
    }
}
