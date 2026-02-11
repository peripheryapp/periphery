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

// Test case for implicitly internal declaration that is redundant.
class ImplicitlyInternalClassUsedOnlyInSameFile {
    var implicitlyInternalProperty: String = "test"

    func useProperty() {
        _ = implicitlyInternalProperty
    }
}

// Retainer to ensure ImplicitlyInternalClassUsedOnlyInSameFile is used in the same file.
public class ImplicitlyInternalRetainer {
    public init() {}

    public func retain() {
        let obj = ImplicitlyInternalClassUsedOnlyInSameFile()
        obj.useProperty()
        _ = obj.implicitlyInternalProperty
    }
}

/*
 Test case for members of private/fileprivate containers.
 Members of a private class are already effectively private,
 so marking them as redundant internal would be misleading.
 */
private class PrivateContainerClass {
    // This should NOT be flagged - already constrained by parent's private accessibility.
    func method() {}

    // This should NOT be flagged - already constrained by parent's private accessibility.
    var property: Int = 0
}

fileprivate class FileprivateContainerClass {
    // This should NOT be flagged - already constrained by parent's fileprivate accessibility.
    func method() {}

    // This should NOT be flagged - already constrained by parent's fileprivate accessibility.
    var property: Int = 0
}

/*
 Test case for deinit - should not be flagged.
 Deinitializers cannot have explicit access modifiers in Swift.
 */
class ClassWithDeinit {
    // This should NOT be flagged - deinit cannot have access modifiers.
    deinit {}
}

/*
 Test case for override methods - should not be flagged.
 Override methods must be at least as accessible as what they override.
 */
class BaseClass {
    func overridableMethod() {}
}

class DerivedClass: BaseClass {
    // This should NOT be flagged - override methods have accessibility constraints.
    override func overridableMethod() {}
}

// Used by main.swift to ensure these are referenced.
class RedundantInternalClassComponents {
    public init() {}
} 