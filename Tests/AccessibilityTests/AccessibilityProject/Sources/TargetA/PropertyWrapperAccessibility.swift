/*
 PropertyWrapperAccessibility.swift
 Tests that property wrapper members are NOT flagged as redundant.
*/

/* Property wrapper with internal accessibility. */
@propertyWrapper
internal struct InternalPropertyWrapper<T> {
    private var value: T

    /* Should NOT be flagged - wrappedValue is part of property wrapper API. */
    internal var wrappedValue: T {
        get { value }
        set { value = newValue }
    }

    /* Should NOT be flagged - projectedValue is part of property wrapper API. */
    internal var projectedValue: InternalPropertyWrapper<T> {
        self
    }

    /* Should NOT be flagged - init is part of property wrapper API. */
    internal init(wrappedValue: T) {
        value = wrappedValue
    }

    /* This typealias is used in the init signature, so it's part of the API. */
    internal typealias Value = T
}

/* Class using the property wrapper. */
internal class ClassUsingPropertyWrapper {
    @InternalPropertyWrapper
    var wrappedProperty: String = "test"

    func access() {
        _ = wrappedProperty
        _ = $wrappedProperty
    }
}

/* Used by main.swift to ensure these are referenced. */
public class PropertyWrapperAccessibilityRetainer {
    public init() {}
    public func retain() {
        let obj = ClassUsingPropertyWrapper()
        obj.access()
    }
}
