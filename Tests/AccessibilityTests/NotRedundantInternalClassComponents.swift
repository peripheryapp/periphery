// NotRedundantInternalClassComponents.swift
// Tests for internal classes/members that should NOT be flagged as redundant

class NotRedundantInternalClassComponents {
    public init() {}
    
    internal func usedInternalMethod() {}
}

internal struct NotRedundantInternalStruct {
    internal var usedInternalProperty: Int = 0
    func useInternalProperty() -> Int {
        return usedInternalProperty
    }
}

internal enum NotRedundantInternalEnum {
    case usedCase
    func useCase() -> NotRedundantInternalEnum {
        return .usedCase
    }
} 
