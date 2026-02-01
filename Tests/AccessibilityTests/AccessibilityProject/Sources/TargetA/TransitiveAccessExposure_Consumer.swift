// TransitiveAccessExposure_Consumer.swift
// Consumer file that references declarations from TransitiveAccessExposure.swift
// This creates cross-file transitive exposure of the inner types.

class TransitiveAccessExposureConsumer {
    // 1. Parameter exposure - calls function with ParameterTypeA parameter
    func consumeParameterExposure() {
        let container = ParameterExposureContainer()
        container.processParameter(ParameterTypeA(value: 42))
    }

    // 2. Return type exposure - calls function returning ReturnTypeA
    func consumeReturnTypeExposure() {
        let container = ReturnTypeExposureContainer()
        let result = container.getResult()
        switch result {
        case .success: break
        case .failure: break
        }
    }

    // 3. Property type exposure - accesses property of PropertyTypeA type
    func consumePropertyTypeExposure() {
        let container = PropertyTypeExposureContainer()
        _ = container.exposedProperty
    }

    // 4. Generic constraint exposure - calls generic function constrained by GenericConstraintProtocolA
    func consumeGenericConstraintExposure() {
        let container = GenericConstraintExposureContainer()
        let item = GenericConstraintConformingTypeA()
        _ = container.processGeneric(item)
    }

    // 5. Protocol requirement exposure - uses conforming type
    func consumeProtocolRequirementExposure() {
        let container = ProtocolRequirementExposureContainer()
        container.process(input: ProtocolRequirementTypeA(payload: 100))
    }

    // 6. Enum associated value exposure - uses enum with associated type
    func consumeEnumAssociatedValueExposure() {
        let container = EnumAssociatedValueExposureContainer()
        let value = container.getEnumValue()
        switch value {
        case .success(let data): _ = data.content
        case .failure: break
        }
    }

    // 7. Typealias exposure - uses typealias property
    func consumeTypealiasExposure() {
        let container = TypealiasExposureContainer()
        _ = container.aliasedProperty
    }

    // 8a. Subscript key exposure - uses subscript with SubscriptKeyTypeA
    func consumeSubscriptKeyExposure() {
        var container = SubscriptExposureContainer()
        let key = SubscriptKeyTypeA(key: "test")
        container[key] = 10
        _ = container[key]
    }

    // 8b. Subscript return type exposure - uses subscript returning SubscriptReturnTypeA
    func consumeSubscriptReturnTypeExposure() {
        let container = SubscriptReturnTypeExposureContainer()
        let item: SubscriptReturnTypeA = container[0]
        _ = item.data
    }

    // 9. Default argument exposure - calls function with default argument
    func consumeDefaultArgumentExposure() {
        let container = DefaultArgumentExposureContainer()
        // Calling with default argument
        container.processWithDefault()
        // Calling with explicit argument
        container.processWithDefault(config: DefaultArgTypeA(config: "custom"))
    }

    // 10. Initializer exposure - calls initializer with InitParamTypeA
    func consumeInitializerExposure() {
        let config = InitParamTypeA(setting: true)
        _ = InitializerExposureContainer(config: config)
    }

    // 11. Closure type exposure - uses closure with exposed types
    func consumeClosureTypeExposure() {
        let container = ClosureTypeExposureContainer()
        let input = ClosureParamTypeA(input: 5)
        let output = container.transformer(input)
        _ = output.output
    }
}
