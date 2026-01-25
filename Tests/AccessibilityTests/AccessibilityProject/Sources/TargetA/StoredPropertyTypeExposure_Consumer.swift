// StoredPropertyTypeExposure_Consumer.swift
// Consumer file that references types from StoredPropertyTypeExposure.swift,
// creating cross-file transitive exposure of the property types.

class StoredPropertyTypeExposureConsumer {
    // Uses StoredPropertyContainer, which transitively exposes StoredPropertyRole
    func consumeSimplePropertyType() {
        let container = StoredPropertyContainer(role: .primary)
        _ = container.role
    }

    // Uses ClassWithNestedType, which transitively exposes NestedPhase
    func consumeNestedType() {
        let obj = ClassWithNestedType()
        obj.advance()
        _ = obj.phase
    }

    // Uses OuterContainer, which transitively exposes MiddleContainer and InnerType
    func consumeChainedPropertyTypes() {
        let outer = OuterContainer(middle: MiddleContainer(inner: InnerType(value: 100)))
        _ = outer.middle.inner.value
    }
}
