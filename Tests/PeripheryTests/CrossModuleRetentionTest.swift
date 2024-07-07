import XCTest
import SystemPackage
@testable import TestShared
@testable import PeripheryKit

final class CrossModuleRetentionTest: SourceGraphTestCase {
    static override func setUp() {
        super.setUp()

        build(driver: SPMProjectDriver.self, projectPath: FixturesProjectPath)
        index()
    }

    func testCrossModuleInheritanceWithSameName() {
        module("CrossModuleRetentionFixtures") {
            self.assertReferenced(.class("FixtureClass129"))
        }

        module("CrossModuleRetentionSupportFixtures") {
            self.assertReferenced(.class("FixtureClass129"))
        }
    }
}
