// NotRedundantFilePrivateComponents.swift
// Tests for fileprivate classes/members that should NOT be flagged as redundant

fileprivate class NotRedundantFilePrivateClass {
    fileprivate func usedFilePrivateMethod() {}
    func publicMethodCallingFilePrivate() {
        usedFilePrivateMethod()
    }
}

fileprivate struct NotRedundantFilePrivateStruct {
    fileprivate var usedFilePrivateProperty: Int = 0
    func useProperty() -> Int {
        return usedFilePrivateProperty
    }
}

fileprivate enum NotRedundantFilePrivateEnum {
    case usedCase
    func useCase() -> NotRedundantFilePrivateEnum {
        return .usedCase
    }
}

// Used by main.swift to ensure these are referenced
class NotRedundantFilePrivateComponents {
    public init() {}
} 