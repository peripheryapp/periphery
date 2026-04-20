// Test file for @usableFromInline attribute handling

public struct PublicContainer {
    // This should NOT be flagged as redundant internal because it has @usableFromInline.
    // @usableFromInline requires the declaration to remain internal (or package) so it can
    // be inlined into client code.
    @usableFromInline
    internal init() {}

    // This should NOT be flagged as redundant internal because of @usableFromInline.
    @usableFromInline
    internal func inlinableHelper() -> Int {
        42
    }

    // This should NOT be flagged as redundant internal because of @usableFromInline.
    @usableFromInline
    internal var inlinableProperty: String {
        "value"
    }

    // This should NOT be flagged as redundant internal.
    // Even though it's only used in this file, @usableFromInline means it could be
    // inlined into client code that imports this module.
    @usableFromInline
    internal static func inlinableStaticMethod() -> Bool {
        true
    }

    // Public method that uses the @usableFromInline members
    @inlinable
    public func publicInlinableMethod() -> String {
        "\(inlinableProperty): \(inlinableHelper())"
    }
}

// This SHOULD be flagged as redundant internal - no @usableFromInline attribute
// and only used within the same file in a non-inlinable private function.
internal func regularInternalMethod() -> String {
    PublicContainer.inlinableStaticMethod().description
}

// Use the regular internal method within the same file
private func useRegularMethod() {
    _ = regularInternalMethod()
}
