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
    }

    enum Kind: String, RawRepresentable, CaseIterable {
        case `associatedtype` = "source.lang.swift.decl.associatedtype"
        case `class` = "source.lang.swift.decl.class"
        case `enum` = "source.lang.swift.decl.enum"
        case enumelement = "source.lang.swift.decl.enumelement"
        case `extension` = "source.lang.swift.decl.extension"
        case extensionClass = "source.lang.swift.decl.extension.class"
        case extensionEnum = "source.lang.swift.decl.extension.enum"
        case extensionProtocol = "source.lang.swift.decl.extension.protocol"
        case extensionStruct = "source.lang.swift.decl.extension.struct"
        case functionAccessorAddress = "source.lang.swift.decl.function.accessor.address"
        case functionAccessorDidset = "source.lang.swift.decl.function.accessor.didset"
        case functionAccessorGetter = "source.lang.swift.decl.function.accessor.getter"
        case functionAccessorMutableaddress = "source.lang.swift.decl.function.accessor.mutableaddress"
        case functionAccessorSetter = "source.lang.swift.decl.function.accessor.setter"
        case functionAccessorWillset = "source.lang.swift.decl.function.accessor.willset"
        case functionConstructor = "source.lang.swift.decl.function.constructor"
        case functionDestructor = "source.lang.swift.decl.function.destructor"
        case functionFree = "source.lang.swift.decl.function.free"
        case functionMethodClass = "source.lang.swift.decl.function.method.class"
        case functionMethodInstance = "source.lang.swift.decl.function.method.instance"
        case functionMethodStatic = "source.lang.swift.decl.function.method.static"
        case functionOperator = "source.lang.swift.decl.function.operator"
        case functionOperatorInfix = "source.lang.swift.decl.function.operator.infix"
        case functionOperatorPostfix = "source.lang.swift.decl.function.operator.postfix"
        case functionOperatorPrefix = "source.lang.swift.decl.function.operator.prefix"
        case functionSubscript = "source.lang.swift.decl.function.subscript"
        case genericTypeParam = "source.lang.swift.decl.generic_type_param"
        case module = "source.lang.swift.decl.module"
        case precedenceGroup = "source.lang.swift.decl.precedencegroup"
        case `protocol` = "source.lang.swift.decl.protocol"
        case `struct` = "source.lang.swift.decl.struct"
        case `typealias` = "source.lang.swift.decl.typealias"
        case varClass = "source.lang.swift.decl.var.class"
        case varGlobal = "source.lang.swift.decl.var.global"
        case varInstance = "source.lang.swift.decl.var.instance"
        case varLocal = "source.lang.swift.decl.var.local"
        case varParameter = "source.lang.swift.decl.var.parameter"
        case varStatic = "source.lang.swift.decl.var.static"

        static var functionKinds: Set<Kind> {
            return Set(Kind.allCases.filter { $0.isFunctionKind })
        }

        var isFunctionKind: Bool {
            return rawValue.hasPrefix("source.lang.swift.decl.function")
        }

        static var variableKinds: Set<Kind> {
            return Set(Kind.allCases.filter { $0.isVariableKind })
        }

        var isVariableKind: Bool {
            return rawValue.hasPrefix("source.lang.swift.decl.var")
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
            return Set(Kind.allCases.filter { $0.isExtensionKind })
        }

        var isExtensionKind: Bool {
            return rawValue.hasPrefix("source.lang.swift.decl.extension")
        }

        static var accessorKinds: Set<Kind> {
            return Set(Kind.allCases.filter { $0.isAccessorKind })
        }

        var isAccessorKind: Bool {
            return rawValue.hasPrefix("source.lang.swift.decl.function.accessor")
        }

        static var accessibleKinds: Set<Kind> {
            return functionKinds.union(variableKinds).union(globalKinds)
        }

        var shortName: String {
            let namespace = "source.lang.swift.decl"
            let index = rawValue.index(after: namespace.endIndex)
            return String(rawValue.suffix(from: index))
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

        func isEqualToStructure(kind: Kind?) -> Bool {
            guard let kind = kind else { return false }
            guard self != kind else { return true }

            if self == .functionConstructor && kind == .functionMethodInstance {
                return true
            }

            if kind == .extension && isExtensionKind {
                return true
            }

            return false
        }

        var referenceEquivalent: Reference.Kind? {
            let value = rawValue.replacingOccurrences(of: ".decl.", with: ".ref.")
            return Reference.Kind(rawValue: value)
        }
    }

    public let location: SourceLocation
    let kind: Kind
    let usr: String

    var parent: Entity?
    var attributes: Set<String> = []
    var declarations: Set<Declaration> = []
    var unusedParameters: Set<Declaration> = []
    var references: Set<Reference> = []
    var related: Set<Reference> = []
    var name: String?
    var structureAccessibility: Accessibility = .internal
    var analyzerHints: [Analyzer.Hint] = []
    var isImplicit: Bool = false

    var attributeAccessibility: Accessibility {
        if attributes.contains("public") {
            return .public
        } else if attributes.contains("open") {
            return .open
        } else if attributes.contains("private") {
            return .private
        } else if attributes.contains("fileprivate") {
            return .fileprivate
        }

        return .internal
    }

    var accessibility: Accessibility {
        let featureManager: FeatureManager = inject()

        if featureManager.isEnabled(.determineAccessibilityFromStructure) {
            return structureAccessibility
        }

        return attributeAccessibility
    }

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
        return Set(declarations.flatMap { $0.descendentDeclarations }).union(declarations)
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
        return "Declaration(\(descriptionParts.joined(separator: ", ")))"
    }

    public var descriptionParts: [String] {
        let formattedName = name != nil ? "'\(name!)'" : "nil"
        let formattedAttributes = "[" + attributes.map { $0 }.sorted().joined(separator: ", ") + "]"
        let implicitOrExplicit = isImplicit ? "implicit" : "explicit"
        return [kind.shortName, formattedName, implicitOrExplicit, accessibility.shortName, formattedAttributes, "'\(usr)'", location.shortDescription]
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
