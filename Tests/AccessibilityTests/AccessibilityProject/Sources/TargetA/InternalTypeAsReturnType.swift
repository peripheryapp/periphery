// InternalTypeAsReturnType.swift
// Tests for internal types used as return types of functions called from other files.
// These should NOT be flagged as redundant internal.

// This internal enum is used as the return type of a function that is called from another file.
// Even though InternalReturnTypeEnum is never directly referenced outside this file,
// it is transitively exposed through the function's return type.
internal enum InternalReturnTypeEnum {
    case value
}

internal class InternalReturnTypeContainer {
    func getEnum() -> InternalReturnTypeEnum {
        return .value
    }
}

public class InternalTypeAsReturnTypeRetainer {
    public init() {}

    public func retain() {
        let container = InternalReturnTypeContainer()
        _ = container.getEnum()
    }
}
