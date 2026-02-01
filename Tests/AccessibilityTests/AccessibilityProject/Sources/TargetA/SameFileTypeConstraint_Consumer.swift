class SameFileTypeConstraintConsumer {
    func consumePropertyType() {
        _ = SameFileConstrainingStruct(enumValue: .one)
    }

    func consumeReturnType() {
        let obj = SameFileClassWithReturnType()
        _ = obj.getReturnType()
    }

    func consumeParamType() {
        let obj = SameFileClassWithParamType()
        obj.process(SameFileParamType(data: "test"))
    }
}
