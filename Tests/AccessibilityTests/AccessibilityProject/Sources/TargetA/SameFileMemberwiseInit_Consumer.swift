class SameFileMemberwiseInitConsumer {
    func consume() {
        let inner = SameFileMemberwiseStruct(field1: "test", field2: 42)
        _ = SameFileOuterStruct(inner: inner)
    }
}
