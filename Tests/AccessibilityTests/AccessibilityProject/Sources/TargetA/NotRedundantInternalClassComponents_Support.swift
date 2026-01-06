// NotRedundantInternalClassComponents_Support.swift
// Support types/usages for NotRedundantInternalClassComponents

internal class NotRedundantInternalClass_Support {
    internal func helper() {}
}

// Used by main.swift to ensure these are referenced
class NotRedundantInternalClassComponents_Support {
    public init() {}
    
    func useInternalMethod() {
        let cls = NotRedundantInternalClass()
        cls.usedInternalMethod()
    }
} 