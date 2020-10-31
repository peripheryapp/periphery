import Foundation
import PathKit

public final class Declaration: Entity, CustomStringConvertible {
    enum RetentionReason {
        case xib
        case unknown
        case applicationMain
        case publicAccessible
        case objcAnnotated
        case unknownTypeExtension
        case unknownTypeConformance
        case mainEntryPoint
        case xctest
        case rootEquatableInfixOperator
        case paramFuncOverridden
        case paramFuncForeginProtocol
        case paramFuncLocalProtocol
        case swiftUIPreviewProvider
        case structImplicitConstructorProperty
        case implicit
        case definesExternalAssociatedType
        case stringInterpolationAppendInterpolation
    }

    enum Kind: String, RawRepresentable, CaseIterable {
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

        static var functionKinds: Set<Kind> {
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

        var isExtensionKind: Bool {
            rawValue.hasPrefix("extension")
        }

        static var accessorKinds: Set<Kind> {
            Set(Kind.allCases.filter { $0.isAccessorKind })
        }

        var isAccessorKind: Bool {
            rawValue.hasPrefix("function.accessor")
        }

        static var accessibleKinds: Set<Kind> {
            functionKinds.union(variableKinds).union(globalKinds)
        }

        var displayName: String? {
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
            default:
                return nil
            }
        }

        var referenceEquivalent: Reference.Kind? {
            Reference.Kind(rawValue: rawValue)
        }
    }

    public let location: SourceLocation
    let kind: Kind
    let usr: String

    var parent: Entity?
    var attributes: Set<String> = []
    var modifiers: Set<String> = []
    var declarations: Set<Declaration> = []
    var unusedParameters: Set<Declaration> = []
    var references: Set<Reference> = []
    var related: Set<Reference> = []
    var name: String?
    var accessibility: (value: Accessibility, isExplicit: Bool) = (.internal, false)
    var isImplicit: Bool = false

    var ancestralDeclarations: Set<Declaration> {
        var entity: Entity? = parent
        var declarations: Set<Declaration> = []

        while let thisEntity = entity {
            if let declaration = thisEntity as? Declaration {
                declarations.insert(declaration)
            }

            entity = thisEntity.parent
        }

        return declarations
    }

    var descendentDeclarations: Set<Declaration> {
        Set(declarations.flatMap { $0.descendentDeclarations }).union(declarations)
    }

    var immediateSuperclassReferences: Set<Reference> {
        let superclassReferences = related.filter { [.class, .struct, .protocol].contains($0.kind) }

        // SourceKit returns inherited typealiases as a Reference instead of a Related.
        let typealiasReferences = references.filter { $0.kind == .typealias }
        return superclassReferences.union(typealiasReferences)
    }

    var isComplexProperty: Bool {
        return declarations.contains {
            if [.functionAccessorWillset,
                .functionAccessorDidset].contains($0.kind) {
                return true
            }

            // All properties have a getter and setter, however they only have a name when
            // explicitly implemented.

            if $0.name != nil,
                [.functionAccessorGetter,
                 .functionAccessorSetter].contains($0.kind) {
                return true
            }

            return false
        }
    }

    public var description: String {
        "Declaration(\(descriptionParts.joined(separator: ", ")))"
    }

    public var descriptionParts: [String] {
        let formattedName = name != nil ? "'\(name!)'" : "nil"
        let formattedAttributes = "[" + attributes.map { $0 }.sorted().joined(separator: ", ") + "]"
        let formattedModifiers = "[" + modifiers.map { $0 }.sorted().joined(separator: ", ") + "]"
        let implicitOrExplicit = isImplicit ? "implicit" : "explicit"
        return [kind.rawValue,
                formattedName,
                implicitOrExplicit,
                accessibility.value.rawValue,
                formattedModifiers,
                formattedAttributes,
                "'\(usr)'",
                location.shortDescription]
    }

    init(kind: Kind, usr: String, location: SourceLocation) {
        self.kind = kind
        self.usr = usr
        self.location = location
    }

    func isDeclaredInExtension(kind: Declaration.Kind) -> Bool {
        guard let parent = parent as? Declaration else { return false }
        return parent.kind == kind
    }

    // MARK: - Analyzer Marking

    private(set) var isRetained: Bool = false // retained regardless of presence of references
    private(set) var retentionReason: RetentionReason = .unknown

    func markRetained(reason: RetentionReason) {
        isRetained = true
        retentionReason = reason
    }
}

extension Declaration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(usr)
        hasher.combine(name)
        hasher.combine(location)
    }
}

extension Declaration: Equatable {
    public static func == (lhs: Declaration, rhs: Declaration) -> Bool {
        let usrIsEqual = lhs.usr == rhs.usr
        let kindIsEqual = lhs.kind == rhs.kind
        let nameIsEqual = lhs.name == rhs.name
        let locationIsEqual = lhs.location == rhs.location
        let implicitEqual = lhs.isImplicit == rhs.isImplicit

        return kindIsEqual && usrIsEqual && nameIsEqual && locationIsEqual && implicitEqual
    }
}
