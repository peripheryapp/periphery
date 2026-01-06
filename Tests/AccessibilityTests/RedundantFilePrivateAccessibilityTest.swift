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

    func testNotRedundantFilePrivatePropertyInPrivateClass() {
        index()
        assertNotRedundantFilePrivateAccessibility(.varInstance("filePrivatePaths"))
    }

    // NOTE: the opposite of the above, e.g. a function called "assertRedundantFilePrivateAccessibility()",
    // is intentionally not tested here.
    //
    // After fixing the bug where cross-type same-file references were incorrectly
    // flagged as redundant, there are no meaningful test cases for truly redundant
    // fileprivate declarations. Here's why:
    //
    // - Fileprivate exists specifically for same-file cross-type access
    // - A fileprivate declaration used only within its own type should be private
    // - A fileprivate declaration with no references at all is marked as "unused", not
    // "redundant fileprivate"
}
