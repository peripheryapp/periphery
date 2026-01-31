// NestedEnumChildReferenceAccessibility_Consumer.swift
// Cross-file consumer that uses nested enum cases via type inference.
// This creates cross-file references to the enum cases without directly
// referencing the parent enum type.

class NestedEnumChildReferenceConsumer {
    func consume() {
        // Uses .large via type inference — the indexer references the enum case
        // but not TransportButtonSize itself.
        _ = TransportButtonHost(size: .large)
    }
}
