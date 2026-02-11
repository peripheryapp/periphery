/*
 ExternalProtocolSignatureType.swift
 Tests that types used in external protocol requirement signatures are NOT
 flagged as redundant internal.

 When a type is used as the return type or parameter type of a method that
 implements an external protocol requirement (like NSViewRepresentable.makeNSView),
 the type must remain internal because the protocol method can't be more
 restrictive than the protocol requires.

 This mimics patterns like:
 - NSViewRepresentable/UIViewRepresentable returning custom NSView/UIView subclasses
 - Codable types with custom coding containers
*/

import Foundation

// This type is used as the return type of an external protocol requirement.
// It should NOT be flagged as redundant internal because Equatable.== must
// remain internal, and its parameter types must be at least as accessible.
internal struct TypeUsedInExternalProtocolSignature: Equatable {
    internal var value: Int

    // The == function is an external protocol requirement (from Equatable).
    // Since this struct conforms to Equatable, the == method's parameter type
    // (this struct) must remain internal.
}

// Usage to retain the type
public class ExternalProtocolSignatureTypeRetainer {
    public init() {}

    public func retain() {
        let a = TypeUsedInExternalProtocolSignature(value: 1)
        let b = TypeUsedInExternalProtocolSignature(value: 2)
        _ = a == b
    }
}
