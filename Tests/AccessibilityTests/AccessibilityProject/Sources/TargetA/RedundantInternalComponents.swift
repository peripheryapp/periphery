// RedundantInternalComponents.swift
// Tests for internal classes/members that should be flagged as redundant

internal class RedundantInternalClass {
    internal func unusedInternalMethod() {}
}

internal struct RedundantInternalStruct {
    internal var unusedInternalProperty: Int = 0
}

internal enum RedundantInternalEnum {
    case unusedCase
}

// Used by main.swift to ensure these are referenced
class RedundantInternalClassComponents {
    public init() {}
} 