/*
 TrulyRedundantFilePrivateMembers.swift
 Tests cases where fileprivate is truly redundant and should be private.
*/

/* This class has a fileprivate method that is only used within the class itself. */
class ClassWithRedundantFilePrivateMethod {
    /* Should be flagged as redundant - only used within the same type (can be private). */
    fileprivate func helper() -> Int {
        42
    }

    func publicMethod() -> Int {
        helper()
    }
}

/* This struct has a fileprivate property only accessed within its own type. */
struct StructWithRedundantFilePrivateProperty {
    /* Should be flagged as redundant - only used within the same type (can be private). */
    fileprivate var internalState: String = ""

    func access() -> String {
        internalState
    }
}

/* Used by main.swift to ensure these are referenced. */
public class TrulyRedundantFilePrivateMembersRetainer {
    public init() {}
    public func retain() {
        let obj = ClassWithRedundantFilePrivateMethod()
        _ = obj.publicMethod()

        let s = StructWithRedundantFilePrivateProperty()
        _ = s.access()
    }
}
