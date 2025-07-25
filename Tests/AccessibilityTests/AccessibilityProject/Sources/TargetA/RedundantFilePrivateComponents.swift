// RedundantFilePrivateComponents.swift
// Tests for fileprivate classes/members that should be flagged as redundant

fileprivate class RedundantFilePrivateClass {
    fileprivate func unusedFilePrivateMethod() {}
}

fileprivate struct RedundantFilePrivateStruct {
    fileprivate var unusedFilePrivateProperty: Int = 0
}

fileprivate enum RedundantFilePrivateEnum {
    case unusedCase
}

// Used by main.swift to ensure these are referenced
class RedundantFilePrivateComponents {
    public init() {}
} 