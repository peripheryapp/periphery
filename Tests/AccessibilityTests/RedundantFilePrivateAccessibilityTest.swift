import Configuration
@testable import TestShared
import XCTest

final class RedundantFilePrivateAccessibilityTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()
        _ = RedundantFilePrivateClass()
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
        NotRedundantFilePrivateClass.staticMethodCallingFilePrivate()
        assertNotRedundantFilePrivateAccessibility(.class("NotRedundantFilePrivateClass"))
    }
}

fileprivate class NotRedundantFilePrivateClass {
    fileprivate static func usedFilePrivateMethod() {}
    
    static func staticMethodCallingFilePrivate() {
        usedFilePrivateMethod()
    }
}

fileprivate class RedundantFilePrivateClass {
    fileprivate func unusedFilePrivateMethod() {}
}
 
