@testable import PeripheryKit
import SystemPackage
@testable import TestShared
import XCTest

// swiftlint:disable:next balanced_xctest_lifecycle
final class CrossModuleRetentionTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        configuration.targets = ["CrossModuleRetentionFixtures", "CrossModuleRetentionSupportFixtures"]
        build(driver: SPMProjectDriver.self)
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
