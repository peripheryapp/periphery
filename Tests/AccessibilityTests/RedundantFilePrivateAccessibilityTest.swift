import Configuration
@testable import TestShared
import XCTest

final class RedundantFilePrivateAccessibilityTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()
        build(projectPath: AccessibilityProjectPath)
    }
    
    func testRedundantFilePrivateClass() {
        // This should be flagged as redundant
        index()
        assertRedundantFilePrivateAccessibility(.class("RedundantFilePrivateClass"))
    }
    
    func testNotRedundantFilePrivateClass() {
        // This should NOT be flagged as redundant
        index()
        assertNotRedundantFilePrivateAccessibility(.class("NotRedundantFilePrivateClass"))
    }
} 