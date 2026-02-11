/*
 NestedTypeAccessibility.swift
 Tests nested type accessibility analysis and redundancy suppression.
*/

/* Public class with internal nested types that are only used within the file. */
public class OuterClassWithNestedTypes {
    /* Should be flagged as redundant (not used outside file). */
    internal struct NestedStruct {
        /* Should NOT be flagged if parent is already flagged (nested redundancy suppression). */
        internal var nestedProperty: Int = 0

        /* Should NOT be flagged if parent is already flagged (nested redundancy suppression). */
        internal func nestedMethod() {}
    }

    /* Should be flagged as redundant (not used outside file). */
    internal class NestedClass {
        /* Should NOT be flagged if parent is already flagged (nested redundancy suppression). */
        internal var anotherProperty: String = ""
    }

    internal var nested: NestedStruct = .init()

    public init() {}

    public func useNested() {
        _ = nested.nestedProperty
        nested.nestedMethod()

        let nc = NestedClass()
        _ = nc.anotherProperty
    }
}

/* Used by main.swift to ensure these are referenced. */
public class NestedTypeAccessibilityRetainer {
    public init() {}
    public func retain() {
        let obj = OuterClassWithNestedTypes()
        obj.useNested()
    }
}
