/*
 MemberwiseInitCalledFromDifferentType.swift
 Tests that struct properties are NOT flagged as redundant internal when the
 struct's implicit memberwise initializer is called from a different type
 in the same file.

 When a ViewModifier or another type creates a struct using its memberwise init,
 the properties need at least fileprivate access and should not be flagged.
*/

struct MemberwiseInitStruct {
    var crossTypeProperty1: String
    var crossTypeProperty2: Int
}

class MemberwiseInitCaller {
    func create() -> MemberwiseInitStruct {
        MemberwiseInitStruct(crossTypeProperty1: "hello", crossTypeProperty2: 42)
    }
}

public class MemberwiseInitCalledFromDifferentTypeRetainer {
    public init() {}
    public func retain() {
        _ = MemberwiseInitCaller().create()
    }
}
