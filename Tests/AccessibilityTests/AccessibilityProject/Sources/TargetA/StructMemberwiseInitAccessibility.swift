/*
 StructMemberwiseInitAccessibility.swift
 Tests that struct stored properties used in implicit memberwise initializers
 are NOT flagged as redundant internal.

 When a struct relies on its implicit memberwise initializer, the stored
 properties that are parameters to that initializer are part of the struct's
 public API and must maintain their accessibility.
*/

// Struct with internal stored properties used in memberwise init.
// These properties should NOT be flagged as redundant internal.
public struct StructWithMemberwiseInit {
    internal var memberwiseProperty1: String
    internal var memberwiseProperty2: Int
    internal let memberwiseConstant: Bool

    // No explicit init - relies on implicit memberwise init
}

// Struct with mixed properties - some in memberwise init, some not.
public struct StructWithMixedProperties {
    internal var memberwiseProperty: String

    // Computed property - not part of memberwise init
    internal var computedProperty: String { memberwiseProperty.uppercased() }

    // Property with default value - still part of memberwise init
    internal var propertyWithDefault: Int = 42

    // No explicit init - relies on implicit memberwise init
}

// Usage within the file to exercise the structs.
public class StructMemberwiseInitAccessibilityRetainer {
    public init() {}

    public func retain() {
        // Using memberwise initializer
        let s1 = StructWithMemberwiseInit(
            memberwiseProperty1: "hello",
            memberwiseProperty2: 42,
            memberwiseConstant: true
        )
        _ = s1

        let s2 = StructWithMixedProperties(
            memberwiseProperty: "world",
            propertyWithDefault: 100
        )
        _ = s2.computedProperty
    }
}
