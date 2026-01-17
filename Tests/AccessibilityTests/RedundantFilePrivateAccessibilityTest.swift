import Configuration
@testable import TestShared
import XCTest

final class RedundantFilePrivateAccessibilityTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()
        build(projectPath: AccessibilityProjectPath)
    }

    // Tests that a fileprivate class is NOT flagged as redundant when accessed
    // from a different type in the same file.
    //
    // In Swift, private and fileprivate have distinct meanings even for top-level declarations:
    // - private: accessible only within the lexical scope and its extensions in the same file
    // - fileprivate: accessible from anywhere in the same file
    //
    // Since RedundantFilePrivateClass is accessed from RedundantFilePrivateClassRetainer
    // (a different type), fileprivate is the minimum access level required. Changing it to
    // private would prevent RedundantFilePrivateClassRetainer from accessing it.
    func testRedundantFilePrivateClass() {
        index()
        assertNotRedundantFilePrivateAccessibility(.class("RedundantFilePrivateClass"))
    }

    func testNotRedundantFilePrivateClass() {
        index()
        assertNotRedundantFilePrivateAccessibility(.class("NotRedundantFilePrivateClass"))
    }

    // Tests that a fileprivate property inside a private class is NOT flagged as redundant.
    // This is valid because fileprivate expands the property's visibility beyond the private
    // container, making it accessible to other types in the same file. The private class
    // restricts access to the file, but fileprivate allows the property to be more visible
    // than its container within that scope.
    func testNotRedundantFilePrivatePropertyInPrivateClass() {
        index()
        assertNotRedundantFilePrivateAccessibility(.varInstance("filePrivatePaths"))
    }

    func testTrulyRedundantFilePrivateMethod() {
        // A fileprivate method only used within its own type should be private.
        index()
        assertRedundantFilePrivateAccessibility(
            .functionMethodInstance("helper()", line: 9),
            containingTypeName: "class ClassWithRedundantFilePrivateMethod"
        )
    }

    func testTrulyRedundantFilePrivateProperty() {
        // A fileprivate property only used within its own type should be private.
        index()
        assertRedundantFilePrivateAccessibility(
            .varInstance("internalState"),
            containingTypeName: "struct StructWithRedundantFilePrivateProperty"
        )
    }
}
