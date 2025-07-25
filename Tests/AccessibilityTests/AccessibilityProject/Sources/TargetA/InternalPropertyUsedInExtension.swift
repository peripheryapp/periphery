// InternalPropertyUsedInExtension.swift
// Tests the case where an internal property is used in an extension in a different file
// This should NOT be flagged as redundant

internal class InternalPropertyUsedInExtension {
    internal var propertyUsedInExtension: String = "test"
    internal var propertyOnlyUsedInSameFile: String = "test" // This should be flagged as redundant
} 