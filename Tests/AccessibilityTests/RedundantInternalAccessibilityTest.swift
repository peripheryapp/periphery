import Configuration
@testable import TestShared
import XCTest

final class RedundantInternalAccessibilityTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()
        build(projectPath: AccessibilityProjectPath)
    }

    func testInternalPropertyUsedInExtensionInOtherFile() {
        // This should NOT be flagged as redundant
        // Tests the case where an internal property is used in an extension in a different file
        index()

        // InternalPropertyUsedInExtension.propertyUsedInExtension should NOT be flagged as redundant
        // because it's used in InternalPropertyExtension.swift
        assertNotRedundantInternalAccessibility(.varInstance("propertyUsedInExtension"))
    }

    func testInternalPropertyUsedOnlyInSameFile() {
        // This should be flagged as redundant
        // Tests the case where an internal property is only used within its own file
        index()

        // InternalPropertyUsedInExtension.propertyOnlyUsedInSameFile should be flagged as redundant
        // because it's only used within InternalPropertyUsedInExtension.swift
        assertRedundantInternalAccessibility(.varInstance("propertyOnlyUsedInSameFile"))
    }

    func testInternalPropertyUsedInMultipleFiles() {
        // This should NOT be flagged as redundant
        // Tests the case where an internal property is used across multiple files
        index()

        // This test would need additional setup with multiple files
        // For now, we'll test that the existing NotRedundantInternalClassComponents work
        assertNotRedundantInternalAccessibility(.class("NotRedundantInternalClass"))
    }

    func testInternalMethodUsedInExtension() {
        // This should NOT be flagged as redundant.
        index()

        assertNotRedundantInternalAccessibility(.functionMethodInstance("usedInternalMethod()"))
    }

    /// Tests that members of a private class are not flagged as redundant internal.
    ///
    /// In Swift, members of a private class are already effectively private due to
    /// the parent's accessibility constraint. Suggesting to change them to fileprivate
    /// would actually increase their visibility, which is incorrect.
    func testMembersOfPrivateClassNotFlagged() {
        index()

        assertNotRedundantInternalAccessibility(.functionMethodInstance("method()", line: 43))
        assertNotRedundantInternalAccessibility(.varInstance("property", line: 46))
    }

    /// Tests that members of a fileprivate class are not flagged as redundant internal
    /// when they would be suggested to be fileprivate.
    ///
    /// In Swift, members of a fileprivate class are already constrained to fileprivate
    /// accessibility. Suggesting to mark them as fileprivate would be redundant.
    func testMembersOfFileprivateClassNotFlagged() {
        index()

        assertNotRedundantInternalAccessibility(.functionMethodInstance("method()", line: 51))
        assertNotRedundantInternalAccessibility(.varInstance("property", line: 54))
    }

    /// Tests that deinit is not flagged as redundant internal.
    ///
    /// In Swift, deinitializers cannot have explicit access modifiers.
    /// They always match the accessibility of their enclosing type.
    func testDeinitNotFlagged() {
        index()

        assertNotRedundantInternalAccessibility(.functionDestructor("deinit", line: 63))
    }

    /// Tests that override methods are not flagged as redundant internal.
    ///
    /// Override methods must be at least as accessible as the method they override,
    /// so their accessibility is constrained by the base method.
    func testOverrideMethodNotFlagged() {
        index()

        assertNotRedundantInternalAccessibility(.functionMethodInstance("overridableMethod()", line: 76))
    }

    /// Tests that protocol requirements are not flagged as redundant internal.
    ///
    /// Methods and properties that implement protocol requirements must maintain
    /// sufficient accessibility to fulfill the protocol contract.
    func testProtocolRequirementsNotFlagged() {
        index()

        assertNotRedundantInternalAccessibility(.functionMethodInstance("requiredMethod()"))
        assertNotRedundantInternalAccessibility(.varInstance("requiredProperty"))
    }

    /// Tests that fileprivate protocol conformances are not flagged.
    func testFilePrivateProtocolConformanceNotFlagged() {
        index()

        assertNotRedundantInternalAccessibility(.functionMethodInstance("filePrivateRequirement()"))
    }

    /// Tests that property wrapper members are not flagged as redundant internal.
    ///
    /// Property wrappers require certain members (init, wrappedValue, projectedValue)
    /// to be accessible as part of their API contract.
    func testPropertyWrapperMembersNotFlagged() {
        index()

        assertNotRedundantInternalAccessibility(.varInstance("wrappedValue"))
        assertNotRedundantInternalAccessibility(.varInstance("projectedValue"))
        assertNotRedundantInternalAccessibility(.functionConstructor("init(wrappedValue:)"))
    }

    /// Tests internal suggesting private.
    ///
    /// An internal property only used within its own type should be private.
    func testInternalSuggestingPrivate() {
        index()

        assertRedundantInternalAccessibility(
            .varInstance("usedOnlyInOwnType"),
            suggestedAccessibility: .private
        )
    }

    /// Tests internal suggesting fileprivate.
    ///
    /// An internal property used from a different type in the same file should be fileprivate.
    func testInternalSuggestingFileprivate() {
        index()

        assertRedundantInternalAccessibility(
            .varInstance("sharedWithClassB"),
            suggestedAccessibility: .fileprivate
        )
    }

    /// Tests nested type redundancy with parent already flagged.
    ///
    /// When nested types are flagged as redundant, their nested members should be
    /// suppressed to avoid noise (unless showNestedRedundantAccessibility is enabled).
    func testNestedTypeRedundancy() {
        index()

        assertRedundantInternalAccessibility(.struct("NestedStruct"))
        assertRedundantInternalAccessibility(.class("NestedClass"))
        assertRedundantInternalAccessibility(.varInstance("nested"))
    }

    /// Tests that implicitly internal declarations (no access modifier) are flagged as redundant
    /// when only used within the same file.
    ///
    /// This ensures the analyzer handles both explicit 'internal' keyword and implicit internal
    /// (default accessibility) correctly in positive cases.
    func testImplicitlyInternalRedundant() {
        index()

        assertRedundantInternalAccessibility(.class("ImplicitlyInternalClassUsedOnlyInSameFile"))
    }

    /// Tests that implicitly internal declarations (no access modifier) are NOT flagged as redundant
    /// when used from another file.
    ///
    /// This ensures the analyzer handles both explicit 'internal' keyword and implicit internal
    /// (default accessibility) correctly in negative cases.
    func testImplicitlyInternalNotRedundant() {
        index()

        assertNotRedundantInternalAccessibility(.struct("ImplicitlyInternalStructUsedFromAnotherFile"))
    }
}
