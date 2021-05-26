class PropertyVisitorTestFixture {
    struct CustomType: Hashable {
        struct NestedType {
            typealias NestedScalar = Int
        }
    }

    let implicitTypeProperty = ""
    let boolProperty: Bool = true
    let optionalBoolProperty: Bool? = true
    let arrayLiteralProperty: [CustomType] = []
    let optionalArrayLiteralProperty: [CustomType]? = []
    let genericProperty: Set<CustomType> = []
    let tupleProperty: (Int, String) = (1, "2")
    let (destructuringPropertyA, destructuringPropertyB): (CustomType, String) = (.init(), "1")
    let (destructuringPropertyC,
         destructuringPropertyD,
         destructuringPropertyE):
        (CustomType.NestedType, CustomType.NestedType.NestedScalar, Swift.String) = (.init(), 1, "1")
    let (implicitDestructuringPropertyA, implicitDestructuringPropertyB) = (CustomType(), "1")
    let multipleBindingPropertyA: Int = 1, multipleBindingPropertyB: String = ""
}
