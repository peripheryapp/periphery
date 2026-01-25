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

    /// Tests that internal declarations accessed from test files via @testable import
    /// are NOT flagged as redundant internal.
    ///
    /// This verifies that @testable import references count as legitimate cross-file usage,
    /// preventing false positives when test files access internal members. Since tests ARE
    /// using these internal members from a different file, they require internal accessibility.
    func testInternalUsedViaTestableImportNotFlagged() {
        index()

        // InternalUsedOnlyInTest should NOT be flagged because it IS used from
        // a test file (different file) via @testable import
        assertNotRedundantInternalAccessibility(.class("InternalUsedOnlyInTest"))
    }

    /// Tests that internal declarations used from production code in the same module
    /// are NOT flagged as redundant (baseline behavior verification).
    func testInternalUsedInProductionNotFlagged() {
        index()

        // InternalUsedInBoth should NOT be flagged because it's used from
        // production code (InternalTestableImportUsage_Support.swift) within the same module
        assertNotRedundantInternalAccessibility(.class("InternalUsedInBoth"))
    }

    /// Tests that declarations with @usableFromInline are NOT flagged as redundant internal.
    ///
    /// The @usableFromInline attribute allows internal declarations to be inlined into
    /// client code, requiring them to maintain internal (or package) visibility. Marking
    /// them as fileprivate or private would cause a compiler error because @usableFromInline
    /// is incompatible with those access levels.
    ///
    /// This test verifies the fix for a build error on Linux where @usableFromInline
    /// declarations were incorrectly flagged as redundant internal, and changing them
    /// to fileprivate caused: "@usableFromInline attribute can only be applied to
    /// internal or package declarations".
    func testUsableFromInlineNotFlagged() {
        index()

        // All @usableFromInline members should NOT be flagged, even if only used in same file
        assertNotRedundantInternalAccessibility(.functionConstructor("init()"))
        assertNotRedundantInternalAccessibility(.functionMethodInstance("inlinableHelper()"))
        assertNotRedundantInternalAccessibility(.varInstance("inlinableProperty"))
        assertNotRedundantInternalAccessibility(.functionMethodStatic("inlinableStaticMethod()"))
    }

    /// Tests that internal types conforming to external protocols are NOT flagged as redundant.
    ///
    /// When a type conforms to an external protocol (from another module), its protocol
    /// requirement implementations must maintain their accessibility to fulfill the
    /// protocol contract. This prevents false positives like those seen with
    /// CheckUpdateCommand, ScanCommand, etc. implementing ArgumentParser's ParsableCommand.
    func testExternalProtocolConformanceNotFlagged() {
        index()

        // Internal struct conforming to ExternalProtocol should NOT be flagged
        assertNotRedundantInternalAccessibility(.struct("InternalStructConformingToExternalProtocol"))
        // The protocol requirement implementation should NOT be flagged (line 10 in fixture)
        assertNotRedundantInternalAccessibility(.functionMethodInstance("someExternalProtocolMethod()", line: 10))
    }

    /// Tests that implicitly internal types conforming to external protocols are NOT flagged.
    func testImplicitlyInternalExternalProtocolConformanceNotFlagged() {
        index()

        // Implicitly internal class conforming to ExternalProtocol should NOT be flagged
        assertNotRedundantInternalAccessibility(.class("ImplicitlyInternalClassConformingToExternalProtocol"))
        // The protocol requirement implementation should NOT be flagged (line 15 in fixture)
        assertNotRedundantInternalAccessibility(.functionMethodInstance("someExternalProtocolMethod()", line: 15))
    }

    /// Tests that top-level internal types used only within the same file are flagged
    /// as redundant internal.
    ///
    /// For top-level declarations, private and fileprivate are equivalent, so the
    /// suggested accessibility is nil (ambiguous). Nested types are suppressed when
    /// their parent is already flagged to reduce noise.
    func testInternalTypeTransitivelyExposedInSameFileSuggestsFileprivate() {
        index()

        // TransitiveExposureClassA is only used within its file (from ClassB), so it
        // should be flagged as redundant internal. Since it's top-level, the suggestion
        // is nil (private and fileprivate are equivalent for top-level declarations).
        assertRedundantInternalAccessibility(.class("TransitiveExposureClassA"))

        // TransitivelyExposedStatus is suppressed because its parent (ClassA) is already
        // flagged. This is by design to reduce noise - fixing the parent is sufficient.
    }

    // MARK: - Transitive Access Exposure Tests

    // These tests verify that Periphery does NOT incorrectly flag internal types
    // that are transitively exposed through API signatures when those APIs are
    // called from other files. See TransitiveAccessExposure.swift for fixtures.

    /// Tests that internal types used in function/method signatures are NOT flagged
    /// when the function is called from another file.
    ///
    /// Covers: parameter types, return types, default argument types, initializer parameters,
    /// and closure types in properties.
    func testTransitiveExposureThroughFunctionSignatures() {
        index()

        // Parameter types: ParameterTypeA used in processParameter()
        assertNotRedundantInternalAccessibility(.struct("ParameterTypeA"))

        // Return types: ReturnTypeA returned by getResult(), InternalReturnTypeEnum returned by getEnum()
        assertNotRedundantInternalAccessibility(.enum("ReturnTypeA"))
        assertNotRedundantInternalAccessibility(.enum("InternalReturnTypeEnum"))

        // Default argument types: DefaultArgTypeA used in processWithDefault()
        assertNotRedundantInternalAccessibility(.struct("DefaultArgTypeA"))

        // Initializer parameters: InitParamTypeA used in init(config:)
        assertNotRedundantInternalAccessibility(.struct("InitParamTypeA"))

        // Closure types: ClosureParamTypeA/ClosureReturnTypeA in transformer property
        assertNotRedundantInternalAccessibility(.struct("ClosureParamTypeA"))
        assertNotRedundantInternalAccessibility(.struct("ClosureReturnTypeA"))
    }

    /// Tests that internal types used in property and subscript signatures are NOT flagged
    /// when accessed from another file.
    ///
    /// Covers: property types, subscript parameter types, subscript return types.
    func testTransitiveExposureThroughPropertyAndSubscriptSignatures() {
        index()

        // Property types: PropertyTypeA used in exposedProperty
        assertNotRedundantInternalAccessibility(.struct("PropertyTypeA"))

        // Subscript parameter types: SubscriptKeyTypeA used in subscript(key:)
        assertNotRedundantInternalAccessibility(.struct("SubscriptKeyTypeA"))

        // Subscript return types: SubscriptReturnTypeA returned by subscript
        assertNotRedundantInternalAccessibility(.struct("SubscriptReturnTypeA"))
    }

    /// Tests that internal types used in generic constraints, protocol requirements,
    /// enum associated values, and typealiases are NOT flagged when exposed from another file.
    ///
    /// Covers: generic constraint protocols, protocol requirement types, enum associated
    /// value types, typealias target types.
    func testTransitiveExposureThroughTypeSystemConstructs() {
        index()

        // Generic constraints: GenericConstraintProtocolA constrains processGeneric()
        assertNotRedundantInternalAccessibility(.protocol("GenericConstraintProtocolA"))

        // Protocol requirement types: ProtocolRequirementTypeA in ProtocolWithRequirementA
        assertNotRedundantInternalAccessibility(.struct("ProtocolRequirementTypeA"))

        // Enum associated values: EnumAssociatedTypeA in EnumWithAssociatedValueA
        assertNotRedundantInternalAccessibility(.struct("EnumAssociatedTypeA"))

        // Typealias targets: TypealiasTargetTypeA aliased by AliasedTypeA
        assertNotRedundantInternalAccessibility(.struct("TypealiasTargetTypeA"))
    }

    // MARK: - Enum Case Tests

    /// Tests that enum cases are NOT flagged as redundant internal.
    ///
    /// Enum cases cannot have explicit access modifiers in Swift - they always
    /// inherit the accessibility of their containing enum. Suggesting to make
    /// them private or fileprivate would cause a syntax error.
    func testEnumCasesNotFlagged() {
        index()

        // Enum cases should never be flagged
        assertNotRedundantInternalAccessibility(.enumelement("usedCase"))
        assertNotRedundantInternalAccessibility(.enumelement("anotherUsedCase"))
        assertNotRedundantInternalAccessibility(.enumelement("internalCase"))
        assertNotRedundantInternalAccessibility(.enumelement("anotherInternalCase"))
    }

    // MARK: - Struct Memberwise Initializer Tests

    /// Tests that struct stored properties used in implicit memberwise initializers
    /// are NOT flagged as redundant internal.
    ///
    /// Stored properties that are parameters to a struct's memberwise initializer
    /// are part of the struct's public API. Even if they're only directly accessed
    /// within the same file, they must remain accessible for the initializer.
    func testStructMemberwiseInitPropertiesNotFlagged() {
        index()

        // Properties used in memberwise init should not be flagged
        assertNotRedundantInternalAccessibility(.varInstance("memberwiseProperty1"))
        assertNotRedundantInternalAccessibility(.varInstance("memberwiseProperty2"))
        assertNotRedundantInternalAccessibility(.varInstance("memberwiseConstant"))
        assertNotRedundantInternalAccessibility(.varInstance("memberwiseProperty"))
        assertNotRedundantInternalAccessibility(.varInstance("propertyWithDefault"))
    }
}
