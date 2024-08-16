@testable import TestShared
import XCTest

// swiftlint:disable:next balanced_xctest_lifecycle
class SPMProjectTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        configuration.reset()
        build(projectPath: SPMProjectPath)
        index()
    }

    func testMainEntryFile() {
        assertReferenced(.functionFree("main()"))
    }

    func testCrossModuleReference() {
        assertReferenced(.class("PublicCrossModuleReferenced"))
        assertNotReferenced(.class("PublicCrossModuleNotReferenced"))
    }
}
