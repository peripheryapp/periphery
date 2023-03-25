import XCTest
@testable import TestShared
@testable import PeripheryKit

class SPMProjectTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        configuration.targets = ["SPMProjectKit", "Frontend"]

        build(driver: SPMProjectDriver.self, projectPath: SPMProjectPath)
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
