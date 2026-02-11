// NotRedundantInternalClassComponents_Support.swift
// Support types/usages for NotRedundantInternalClassComponents

internal class NotRedundantInternalClass_Support {
    internal func helper() {}
}

// Used by main.swift to ensure these are referenced.
public class NotRedundantInternalClassComponents_Support {
    public init() {}

    public func useInternalMethod() {
        let cls = NotRedundantInternalClass()
        cls.usedInternalMethod()
    }

    public func useImplicitlyInternalStruct() {
        let s = ImplicitlyInternalStructUsedFromAnotherFile()
        _ = s.implicitlyInternalProperty
    }
} 