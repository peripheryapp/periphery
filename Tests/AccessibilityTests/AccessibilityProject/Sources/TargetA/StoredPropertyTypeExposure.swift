// StoredPropertyTypeExposure.swift
// Test cases for types used as stored property types that are transitively exposed.
//
// When a type T is used as a property type in a struct/class C, and C is instantiated
// from another file, T is transitively exposed and should NOT be flagged as redundant internal.

// MARK: - Simple Property Type Exposure

// StoredPropertyRole is used as the property type in StoredPropertyContainer.
// StoredPropertyContainer is instantiated from StoredPropertyTypeExposure_Consumer.swift.
// Therefore StoredPropertyRole is transitively exposed and should NOT be flagged.
internal enum StoredPropertyRole {
    case primary
    case secondary
}

internal struct StoredPropertyContainer {
    let role: StoredPropertyRole
}

// MARK: - Nested Type as Property Type

// NestedPhase is a nested enum used as a property type in its containing class.
// ClassWithNestedType is instantiated from StoredPropertyTypeExposure_Consumer.swift.
// Therefore NestedPhase is transitively exposed and should NOT be flagged.
internal class ClassWithNestedType {
    internal enum NestedPhase {
        case idle
        case running
        case completed
    }

    var phase: NestedPhase = .idle

    func advance() {
        switch phase {
        case .idle: phase = .running
        case .running: phase = .completed
        case .completed: break
        }
    }
}

// MARK: - Chained Property Type Exposure

// InnerType is used in MiddleContainer, which is used in OuterContainer.
// OuterContainer is instantiated from StoredPropertyTypeExposure_Consumer.swift.
// Therefore both InnerType and MiddleContainer are transitively exposed.
internal struct InnerType {
    var value: Int = 0
}

internal struct MiddleContainer {
    var inner: InnerType
}

internal struct OuterContainer {
    var middle: MiddleContainer
}

// MARK: - Retainer class to ensure all code is exercised

public class StoredPropertyTypeExposureRetainer {
    public init() {}

    public func use() {
        _ = StoredPropertyContainer(role: .primary)
        _ = ClassWithNestedType()
        _ = OuterContainer(middle: MiddleContainer(inner: InnerType(value: 42)))
    }
}
