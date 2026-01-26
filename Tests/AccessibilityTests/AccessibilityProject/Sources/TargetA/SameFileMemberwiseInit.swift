// Tests that struct memberwise init properties are NOT flagged when the init
// is used within the same file AND the struct is part of a type hierarchy
// that must remain internal.

internal struct SameFileMemberwiseStruct {
    let field1: String
    let field2: Int
}

internal struct SameFileOuterStruct {
    let inner: SameFileMemberwiseStruct
}

public class SameFileMemberwiseInitRetainer {
    public init() {}
    public func use() {
        let inner = SameFileMemberwiseStruct(field1: "test", field2: 42)
        _ = SameFileOuterStruct(inner: inner)
    }
}
