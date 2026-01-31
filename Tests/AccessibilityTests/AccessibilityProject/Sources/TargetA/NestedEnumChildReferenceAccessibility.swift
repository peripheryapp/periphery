// NestedEnumChildReferenceAccessibility.swift
// Test cases for nested enums whose cases are referenced from outside the parent type
// via type inference (e.g., `.small` instead of `TransportButtonSize.small`).
//
// When enum cases are used via type inference, the Swift indexer creates references
// to the enum cases but NOT to the parent enum type. Periphery must recognize these
// indirect references to avoid falsely suggesting `private` for the nested enum.

struct TransportButtonHost {
    enum TransportButtonSize {
        case small
        case medium
        case large
    }

    var size: TransportButtonSize

    func description() -> String {
        switch size {
        case .small: "S"
        case .medium: "M"
        case .large: "L"
        }
    }
}

// Same-file consumer that uses enum cases from outside the parent struct.
// This exercises the isReferencedFromDifferentTypeInSameFile child-reference path.
class SameFileTransportConsumer {
    func use() {
        _ = TransportButtonHost(size: .medium)
    }
}

public class NestedEnumChildReferenceAccessibilityRetainer {
    public init() {}
    public func retain() {
        _ = TransportButtonHost(size: .small)
        _ = SameFileTransportConsumer()
    }
}
