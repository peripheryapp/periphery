/*
 InternalSuggestingPrivateVsFileprivate.swift
 Tests that internal declarations correctly suggest private vs fileprivate
 based on whether they're accessed from different types in the same file.
*/

// Class with internal property only used within its own type - should suggest private.
public class ClassWithInternalPropertySuggestingPrivate {
    // Should be flagged as redundant internal (can be 'private').
    internal var usedOnlyInOwnType: Int = 0

    public init() {}

    public func useProperty() {
        _ = usedOnlyInOwnType
    }
}

// Two classes where one accesses the other's internal property - should suggest fileprivate.
public class ClassA {
    // Should be flagged as redundant internal (can be 'fileprivate').
    internal var sharedWithClassB: String = ""

    public init() {}
}

public class ClassB {
    public init() {}

    public func accessClassA(_ a: ClassA) {
        _ = a.sharedWithClassB
    }
}

// Used by main.swift to ensure these are referenced.
public class InternalSuggestingPrivateVsFileprivateRetainer {
    public init() {}
    public func retain() {
        let obj1 = ClassWithInternalPropertySuggestingPrivate()
        obj1.useProperty()

        let a = ClassA()
        let b = ClassB()
        b.accessClassA(a)
    }
}
