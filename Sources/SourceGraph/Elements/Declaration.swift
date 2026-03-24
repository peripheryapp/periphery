import Foundation

public final class Declaration {
    public enum Kind: String, RawRepresentable, CaseIterable, Hashable {
        case `associatedtype`
        case `class`
        case `enum`
        case enumelement
        case `extension`
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
        case functionAccessorRead = "function.accessor.read"
        case functionAccessorModify = "function.accessor.modify"
        case functionAccessorInit = "function.accessor.init"
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
        case module
        case precedenceGroup = "precedencegroup"
        case `protocol`
        case `struct`
        case `typealias`
        case varClass = "var.class"
        case varGlobal = "var.global"
        case varInstance = "var.instance"
        case varLocal = "var.local"
        case varParameter = "var.parameter"
        case varStatic = "var.static"
        case macro

        // Integer discriminator for O(1) hashing/equality, bypassing the default
        // RawRepresentable conformance which hashes the String raw value.
        @usableFromInline var ordinal: Int {
            switch self {
            case .associatedtype: 0
            case .class: 1
            case .enum: 2
            case .enumelement: 3
            case .extension: 4
            case .extensionClass: 5
            case .extensionEnum: 6
            case .extensionProtocol: 7
            case .extensionStruct: 8
            case .functionAccessorAddress: 9
            case .functionAccessorDidset: 10
            case .functionAccessorGetter: 11
            case .functionAccessorMutableaddress: 12
            case .functionAccessorSetter: 13
            case .functionAccessorWillset: 14
            case .functionAccessorRead: 15
            case .functionAccessorModify: 16
            case .functionAccessorInit: 17
            case .functionConstructor: 18
            case .functionDestructor: 19
            case .functionFree: 20
            case .functionMethodClass: 21
            case .functionMethodInstance: 22
            case .functionMethodStatic: 23
            case .functionOperator: 24
            case .functionOperatorInfix: 25
            case .functionOperatorPostfix: 26
            case .functionOperatorPrefix: 27
            case .functionSubscript: 28
            case .genericTypeParam: 29
            case .module: 30
            case .precedenceGroup: 31
            case .protocol: 32
            case .struct: 33
            case .typealias: 34
            case .varClass: 35
            case .varGlobal: 36
            case .varInstance: 37
            case .varLocal: 38
            case .varParameter: 39
            case .varStatic: 40
            case .macro: 41
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

        static let functionKinds: Set<Kind> =
            Set(Kind.allCases.filter(\.isFunctionKind))

        static let variableKinds: Set<Kind> =
            Set(Kind.allCases.filter(\.isVariableKind))

        static let protocolMemberKinds: [Kind] = {
            let functionKinds: [Kind] = [.functionMethodInstance, .functionMethodStatic, .functionSubscript, .functionOperator, .functionOperatorInfix, .functionOperatorPostfix, .functionOperatorPrefix, .functionConstructor]
            let variableKinds: [Kind] = [.varInstance, .varStatic]
            return functionKinds + variableKinds
        }()

        // Protocols cannot declare 'class' members, yet classes can fulfill the requirement
        // with either a 'class' or 'static' member.
        static let protocolMemberConformingKinds: [Kind] =
            protocolMemberKinds + [.varClass, .functionMethodClass, .associatedtype]

        public var isProtocolMemberKind: Bool {
            Self.protocolMemberKinds.contains(self)
        }

        public var isProtocolMemberConformingKind: Bool {
            Self.protocolMemberConformingKinds.contains(self)
        }

        public var isFunctionKind: Bool {
            switch self {
            case .functionAccessorAddress, .functionAccessorDidset, .functionAccessorGetter,
                 .functionAccessorMutableaddress, .functionAccessorSetter, .functionAccessorWillset,
                 .functionAccessorRead, .functionAccessorModify, .functionAccessorInit,
                 .functionConstructor, .functionDestructor, .functionFree,
                 .functionMethodClass, .functionMethodInstance, .functionMethodStatic,
                 .functionOperator, .functionOperatorInfix, .functionOperatorPostfix,
                 .functionOperatorPrefix, .functionSubscript:
                true
            default:
                false
            }
        }

        public var isVariableKind: Bool {
            switch self {
            case .varClass, .varGlobal, .varInstance, .varLocal, .varParameter, .varStatic:
                true
            default:
                false
            }
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
            .varGlobal,
        ]

        static let extensionKinds: Set<Kind> =
            Set(Kind.allCases.filter(\.isExtensionKind))

        public var extendedKind: Kind? {
            switch self {
            case .extensionClass:
                .class
            case .extensionStruct:
                .struct
            case .extensionEnum:
                .enum
            case .extensionProtocol:
                .protocol
            default:
                nil
            }
        }

        public var extensionKind: Kind? {
            switch self {
            case .class:
                .extensionClass
            case .struct:
                .extensionStruct
            case .enum:
                .extensionEnum
            case .protocol:
                .extensionProtocol
            default:
                nil
            }
        }

        public var isExtensionKind: Bool {
            switch self {
            case .extension, .extensionClass, .extensionEnum, .extensionProtocol, .extensionStruct:
                true
            default:
                false
            }
        }

        public var isExtendableKind: Bool {
            isConcreteTypeDeclarableKind || self == .protocol
        }

        public var isConformableKind: Bool {
            isDiscreteConformableKind || isExtensionKind
        }

        public var isDiscreteConformableKind: Bool {
            Self.discreteConformableKinds.contains(self)
        }

        static let discreteConformableKinds: Set<Kind> =
            [.class, .struct, .enum]

        public var isConcreteTypeDeclarableKind: Bool {
            switch self {
            case .class, .struct, .enum, .typealias: true
            default: false
            }
        }

        static let concreteTypeDeclarableKinds: Set<Kind> =
            [.class, .struct, .enum, .typealias]

        static let accessorKinds: Set<Kind> =
            Set(Kind.allCases.filter(\.isAccessorKind))

        static let accessibleKinds: Set<Kind> =
            functionKinds.union(variableKinds).union(globalKinds)

        static let overrideKinds: Set<Kind> =
            [.functionMethodInstance, .varInstance]

        public var isAccessorKind: Bool {
            switch self {
            case .functionAccessorAddress, .functionAccessorDidset, .functionAccessorGetter,
                 .functionAccessorMutableaddress, .functionAccessorSetter, .functionAccessorWillset,
                 .functionAccessorRead, .functionAccessorModify, .functionAccessorInit:
                true
            default:
                false
            }
        }

        static let toplevelAttributableKind: Set<Kind> =
            [.class, .struct, .enum]

        public var displayName: String {
            switch self {
            case .module:
                "imported module"
            case .class:
                "class"
            case .protocol:
                "protocol"
            case .struct:
                "struct"
            case .enum:
                "enum"
            case .enumelement:
                "enum case"
            case .typealias:
                "typealias"
            case .associatedtype:
                "associatedtype"
            case .functionConstructor:
                "initializer"
            case .extension, .extensionEnum, .extensionClass, .extensionStruct, .extensionProtocol:
                "extension"
            case .functionMethodClass, .functionMethodStatic, .functionMethodInstance, .functionFree, .functionOperator, .functionOperatorInfix, .functionOperatorPostfix, .functionOperatorPrefix, .functionSubscript, .functionAccessorAddress, .functionAccessorMutableaddress, .functionAccessorDidset, .functionAccessorGetter, .functionAccessorSetter, .functionAccessorWillset, .functionAccessorRead, .functionAccessorModify, .functionAccessorInit, .functionDestructor:
                "function"
            case .varStatic, .varInstance, .varClass, .varGlobal, .varLocal:
                "property"
            case .varParameter:
                "parameter"
            case .genericTypeParam:
                "generic type parameter"
            case .precedenceGroup:
                "precedence group"
            case .macro:
                "macro"
            }
        }
    }

    public let location: Location
    public var attributes: Set<DeclarationAttribute> = []
    public var modifiers: Set<String> = [] {
        didSet { _isOverride = modifiers.contains("override") }
    }

    private var _isOverride: Bool = false
    public var accessibility: DeclarationAccessibility = .init(value: .internal, isExplicit: false)
    public let kind: Kind
    public let name: String
    public let usrs: Set<String>
    public let usrIDs: [USRID]
    public var unusedParameters: Set<Declaration> = []
    public var declarations: Set<Declaration> = []
    public var commentCommands: Set<CommentCommand> = []
    public var references: Set<Reference> = []
    public var declaredType: String?
    public var hasGenericFunctionReturnedMetatypeParameters: Bool = false
    public var parent: Declaration?
    public var related: Set<Reference> = []
    public var isImplicit: Bool = false
    public var isObjcAccessible: Bool = false
    public internal(set) var isUsed: Bool = false

    private let hashValueCache: Int

    public var ancestralDeclarations: Set<Declaration> {
        var maybeParent = parent
        var declarations: Set<Declaration> = []

        while let thisParent = maybeParent {
            declarations.insert(thisParent)
            maybeParent = thisParent.parent
        }

        return declarations
    }

    public func forEachDescendentDeclaration(_ body: (Declaration) -> Void) {
        for decl in declarations {
            body(decl)
            decl.forEachDescendentDeclaration(body)
        }
        for param in unusedParameters {
            body(param)
            param.forEachDescendentDeclaration(body)
        }
    }

    public var immediateInheritedTypeReferences: Set<Reference> {
        let superclassReferences = related.filter { [.class, .struct, .protocol].contains($0.declarationKind) }

        // Inherited typealiases are References instead of a Related.
        let typealiasReferences = references.filter { $0.declarationKind == .typealias }
        return superclassReferences.union(typealiasReferences)
    }

    public var isComplexProperty: Bool {
        declarations.contains {
            if [
                .functionAccessorWillset,
                .functionAccessorDidset,
            ].contains($0.kind) {
                return true
            }

            if $0.kind.isAccessorKind, !$0.references.isEmpty {
                return true
            }

            return false
        }
    }

    public var isOverride: Bool { _isOverride }

    public var relatedEquivalentReferences: [Reference] {
        related.filter { $0.declarationKind == kind && $0.name == name }
    }

    public init(
        name: String,
        kind: Kind,
        usrs: Set<String>,
        usrIDs: [USRID],
        location: Location
    ) {
        self.name = name
        self.kind = kind
        self.usrs = usrs
        self.usrIDs = usrIDs.count > 1 ? usrIDs.sorted(by: { $0.rawValue < $1.rawValue }) : usrIDs
        self.location = location
        if self.usrIDs.count == 1 {
            hashValueCache = self.usrIDs[0].hashValue
        } else {
            var hasher = Hasher()
            for id in self.usrIDs {
                hasher.combine(id)
            }
            hashValueCache = hasher.finalize()
        }
    }

    func isDeclaredInExtension(kind: Declaration.Kind) -> Bool {
        guard let parent else { return false }

        return parent.kind == kind
    }
}

extension Declaration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValueCache)
    }
}

extension Declaration: Equatable {
    public static func == (lhs: Declaration, rhs: Declaration) -> Bool {
        if lhs === rhs { return true }
        guard lhs.hashValueCache == rhs.hashValueCache else { return false }

        return lhs.usrIDs == rhs.usrIDs
    }
}

extension Declaration: CustomStringConvertible {
    public var description: String {
        "Declaration(\(descriptionParts.joined(separator: ", ")))"
    }

    private var descriptionParts: [String] {
        let formattedName = "'\(name)'"
        let formattedAttributes = "[" + attributes.sorted().map(\.description).joined(separator: ", ") + "]"
        let formattedModifiers = "[" + modifiers.sorted().joined(separator: ", ") + "]"
        let formattedCommentCommands = "[" + commentCommands.map(\.description).sorted().joined(separator: ", ") + "]"
        let formattedUsrs = "[" + usrs.sorted().joined(separator: ", ") + "]"
        let implicitOrExplicit = isImplicit ? "implicit" : "explicit"
        return [
            kind.rawValue,
            formattedName,
            implicitOrExplicit,
            accessibility.value.rawValue,
            formattedModifiers,
            formattedAttributes,
            formattedCommentCommands,
            formattedUsrs,
            location.shortDescription,
        ]
    }
}

extension Declaration: Comparable {
    public static func < (lhs: Declaration, rhs: Declaration) -> Bool {
        var lhsLocation = lhs.location
        var rhsLocation = rhs.location

        if let locationOverride = lhs.commentCommands.locationOverride {
            let (path, line, column) = locationOverride
            let sourceFile = SourceFile(path: path, modules: [])
            lhsLocation = Location(file: sourceFile, line: line, column: column)
        }

        if let locationOverride = rhs.commentCommands.locationOverride {
            let (path, line, column) = locationOverride
            let sourceFile = SourceFile(path: path, modules: [])
            rhsLocation = Location(file: sourceFile, line: line, column: column)
        }

        if lhsLocation == rhsLocation {
            return lhs.usrs.sorted().joined() < rhs.usrs.sorted().joined()
        }

        return lhsLocation < rhsLocation
    }
}

public struct DeclarationAccessibility {
    public let value: Accessibility
    public let isExplicit: Bool

    public init(value: Accessibility, isExplicit: Bool) {
        self.value = value
        self.isExplicit = isExplicit
    }

    func isExplicitly(_ testValue: Accessibility) -> Bool {
        isExplicit && value == testValue
    }

    var isAccessibleCrossModule: Bool {
        value == .public || value == .open
    }
}
