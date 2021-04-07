class PropertyTypeParserTestFixture {
    struct CustomType: Hashable {}

    let boolProperty: Bool = true
    let optionalBoolProperty: Bool? = true
    let arrayLiteralProperty: [CustomType] = []
    let optionalArrayLiteralProperty: [CustomType]? = []
    let genericProperty: Set<CustomType> = []
}
