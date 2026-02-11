// TransitiveAccessExposure.swift
// Comprehensive test cases for transitive access exposure scenarios.
// Each scenario shows a type that must have sufficient access level because
// it is exposed through another declaration's signature.
//
// For each case:
// - The inner type is marked with the minimum required access level
// - A comment shows what error would occur if we lowered the access level
//
// NOTE: This file focuses on CROSS-FILE exposure scenarios (internal types).
// Same-file scenarios (fileprivate types) are handled in a separate file.

// MARK: - 1. Function Parameter Type Exposure

// Scenario 1a: Internal type used as parameter of internal function called from another file
// If ParameterTypeA were fileprivate:
// "Method must be declared fileprivate because its parameter uses a fileprivate type"
internal struct ParameterTypeA {
    var value: Int = 0
}

class ParameterExposureContainer {
    // This function is called from TransitiveAccessExposure_Consumer.swift
    func processParameter(_ param: ParameterTypeA) {
        _ = param.value
    }
}

// MARK: - 2. Function Return Type Exposure

// Scenario 2a: Internal type used as return type of function called from another file
// If ReturnTypeA were fileprivate:
// "Function must be declared fileprivate because its result uses a fileprivate type"
internal enum ReturnTypeA {
    case success
    case failure
}

class ReturnTypeExposureContainer {
    // This function is called from TransitiveAccessExposure_Consumer.swift
    func getResult() -> ReturnTypeA {
        .success
    }
}

// MARK: - 3. Property Type Exposure

// Scenario 3a: Internal type used as property type, property accessed from another file
// If PropertyTypeA were fileprivate:
// "Property must be declared fileprivate because its type uses a fileprivate type"
internal struct PropertyTypeA {
    var data: String = ""
}

class PropertyTypeExposureContainer {
    // This property is accessed from TransitiveAccessExposure_Consumer.swift
    var exposedProperty: PropertyTypeA = PropertyTypeA()
}

// MARK: - 4. Generic Constraint Exposure

// Scenario 4a: Internal protocol used as generic constraint, function called from another file
// If GenericConstraintProtocolA were fileprivate:
// "Generic parameter 'T' cannot be declared internal because it uses a fileprivate type in its requirement"
internal protocol GenericConstraintProtocolA {
    var identifier: String { get }
}

internal struct GenericConstraintConformingTypeA: GenericConstraintProtocolA {
    var identifier: String = "A"
}

class GenericConstraintExposureContainer {
    // This function is called from TransitiveAccessExposure_Consumer.swift
    func processGeneric<T: GenericConstraintProtocolA>(_ item: T) -> String {
        item.identifier
    }
}

// MARK: - 5. Protocol Requirement Exposure
// Note: Protocol requirements expose types in their signatures

// Scenario 5a: Internal type used in protocol requirement parameter
// If ProtocolRequirementTypeA were fileprivate:
// "Method in an internal protocol cannot use a fileprivate type"
internal struct ProtocolRequirementTypeA {
    var payload: Int = 0
}

internal protocol ProtocolWithRequirementA {
    func process(input: ProtocolRequirementTypeA)
}

class ProtocolRequirementExposureContainer: ProtocolWithRequirementA {
    func process(input: ProtocolRequirementTypeA) {
        _ = input.payload
    }
}

// MARK: - 6. Enum Associated Value Exposure

// Scenario 6a: Internal type used as enum associated value, enum used from another file
// If EnumAssociatedTypeA were fileprivate:
// "Enum case in an internal enum uses a fileprivate type"
internal struct EnumAssociatedTypeA {
    var content: String = ""
}

internal enum EnumWithAssociatedValueA {
    case success(EnumAssociatedTypeA)
    case failure(Error)
}

class EnumAssociatedValueExposureContainer {
    // This function is called from TransitiveAccessExposure_Consumer.swift
    func getEnumValue() -> EnumWithAssociatedValueA {
        .success(EnumAssociatedTypeA(content: "data"))
    }
}

// MARK: - 7. Typealias Exposure

// Scenario 7a: Internal type aliased by internal typealias, used from another file
// If TypealiasTargetTypeA were fileprivate:
// "Type alias cannot be declared internal because it uses a fileprivate type"
internal struct TypealiasTargetTypeA {
    var value: Double = 0.0
}

internal typealias AliasedTypeA = TypealiasTargetTypeA

class TypealiasExposureContainer {
    // This property uses the typealias and is accessed from TransitiveAccessExposure_Consumer.swift
    var aliasedProperty: AliasedTypeA = AliasedTypeA()
}

// MARK: - 8. Subscript Exposure

// Scenario 8a: Internal type used as subscript parameter, subscript accessed from another file
// If SubscriptKeyTypeA were fileprivate:
// "Subscript cannot be declared internal because its parameter uses a fileprivate type"
internal struct SubscriptKeyTypeA: Hashable {
    var key: String = ""
}

class SubscriptExposureContainer {
    private var storage: [SubscriptKeyTypeA: Int] = [:]

    // This subscript is accessed from TransitiveAccessExposure_Consumer.swift
    subscript(key: SubscriptKeyTypeA) -> Int {
        get { storage[key] ?? 0 }
        set { storage[key] = newValue }
    }
}

// Scenario 8b: Internal type used as subscript return type
// If SubscriptReturnTypeA were fileprivate:
// "Subscript cannot be declared internal because its element type uses a fileprivate type"
internal struct SubscriptReturnTypeA {
    var data: String = ""
}

class SubscriptReturnTypeExposureContainer {
    private var items: [SubscriptReturnTypeA] = []

    // This subscript is accessed from TransitiveAccessExposure_Consumer.swift
    subscript(index: Int) -> SubscriptReturnTypeA {
        items.indices.contains(index) ? items[index] : SubscriptReturnTypeA()
    }
}

// MARK: - 9. Default Argument Exposure

// Scenario 9a: Internal type used in default argument, function called from another file
// If DefaultArgTypeA were fileprivate:
// "Default argument value of internal function uses a fileprivate type"
internal struct DefaultArgTypeA {
    var config: String = "default"
    static let defaultValue = DefaultArgTypeA()
}

class DefaultArgumentExposureContainer {
    // This function is called from TransitiveAccessExposure_Consumer.swift
    func processWithDefault(config: DefaultArgTypeA = DefaultArgTypeA.defaultValue) {
        _ = config.config
    }
}

// MARK: - 10. Initializer Parameter Exposure

// Scenario 10a: Internal type used as initializer parameter, init called from another file
// If InitParamTypeA were fileprivate:
// "Initializer cannot be declared internal because its parameter uses a fileprivate type"
internal struct InitParamTypeA {
    var setting: Bool = false
}

class InitializerExposureContainer {
    let config: InitParamTypeA

    // This initializer is called from TransitiveAccessExposure_Consumer.swift
    init(config: InitParamTypeA) {
        self.config = config
    }
}

// MARK: - 11. Closure Type Exposure

// Scenario 11a: Internal type used in closure parameter/return, closure accessed from another file
// If ClosureParamTypeA were fileprivate:
// "Property cannot be declared internal because its type uses a fileprivate type"
internal struct ClosureParamTypeA {
    var input: Int = 0
}

internal struct ClosureReturnTypeA {
    var output: Int = 0
}

class ClosureTypeExposureContainer {
    // This closure property is accessed from TransitiveAccessExposure_Consumer.swift
    var transformer: (ClosureParamTypeA) -> ClosureReturnTypeA = { param in
        ClosureReturnTypeA(output: param.input * 2)
    }
}

// MARK: - Retainer class to ensure all code is exercised

public class TransitiveAccessExposureRetainer {
    public init() {}

    public func retain() {
        // 1. Parameter exposure
        _ = ParameterExposureContainer()

        // 2. Return type exposure
        _ = ReturnTypeExposureContainer()

        // 3. Property type exposure
        _ = PropertyTypeExposureContainer()

        // 4. Generic constraint exposure
        _ = GenericConstraintExposureContainer()

        // 5. Protocol requirement exposure
        _ = ProtocolRequirementExposureContainer()

        // 6. Enum associated value exposure
        _ = EnumAssociatedValueExposureContainer()

        // 7. Typealias exposure
        _ = TypealiasExposureContainer()

        // 8. Subscript exposure
        _ = SubscriptExposureContainer()
        _ = SubscriptReturnTypeExposureContainer()

        // 9. Default argument exposure
        _ = DefaultArgumentExposureContainer()

        // 10. Initializer exposure
        _ = InitializerExposureContainer(config: InitParamTypeA())

        // 11. Closure type exposure
        _ = ClosureTypeExposureContainer()
    }
}
