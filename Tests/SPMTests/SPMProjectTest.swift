@testable import PeripheryKit
@testable import TestShared
import XCTest

// swiftlint:disable:next balanced_xctest_lifecycle
final class SPMProjectTest: SourceGraphTestCase {
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
