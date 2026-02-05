/*
 ExternalProtocolConformanceAccessibility.swift
 Tests that types conforming to external protocols are NOT flagged as redundant internal.
*/

import ExternalTarget

// Internal struct conforming to external protocol - should NOT be flagged.
internal struct InternalStructConformingToExternalProtocol: ExternalProtocol {
    func someExternalProtocolMethod() {}
}

// Implicitly internal class conforming to external protocol - should NOT be flagged.
class ImplicitlyInternalClassConformingToExternalProtocol: ExternalProtocol {
    func someExternalProtocolMethod() {}
}

// Used to ensure these types are referenced.
public class ExternalProtocolConformanceRetainer {
    public init() {}
    public func retain() {
        let s = InternalStructConformingToExternalProtocol()
        s.someExternalProtocolMethod()
        let c = ImplicitlyInternalClassConformingToExternalProtocol()
        c.someExternalProtocolMethod()
    }
}
