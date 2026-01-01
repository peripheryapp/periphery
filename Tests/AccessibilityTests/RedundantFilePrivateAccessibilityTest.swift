import Configuration
@testable import TestShared
import XCTest

final class RedundantFilePrivateAccessibilityTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()
        build(projectPath: AccessibilityProjectPath)
    }

    func testRedundantFilePrivateClass() {
        index()
        assertRedundantFilePrivateAccessibility(.class("RedundantFilePrivateClass"))
    }

    func testNotRedundantFilePrivateClass() {
        index()
        assertNotRedundantFilePrivateAccessibility(.class("NotRedundantFilePrivateClass"))
    }
}
