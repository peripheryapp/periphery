/*
 EnumCaseAccessibility.swift
 Tests that enum cases are NOT flagged as redundant internal.

 Enum cases cannot have explicit access modifiers in Swift - they inherit
 the accessibility of their containing enum. Suggesting to make them private
 or fileprivate would cause a syntax error.
*/

// Internal enum with cases only used in this file - should NOT flag the cases.
internal enum InternalEnumWithCasesUsedOnlyInSameFile {
    case usedCase
    case anotherUsedCase
}

// Public enum with internal cases - cases should NOT be flagged.
public enum PublicEnumWithInternalCases {
    case internalCase
    case anotherInternalCase
}

// Usage within the file to exercise the enum cases.
public class EnumCaseAccessibilityRetainer {
    public init() {}

    public func retain() {
        _ = InternalEnumWithCasesUsedOnlyInSameFile.usedCase
        _ = InternalEnumWithCasesUsedOnlyInSameFile.anotherUsedCase
        _ = PublicEnumWithInternalCases.internalCase
        _ = PublicEnumWithInternalCases.anotherInternalCase
    }
}
