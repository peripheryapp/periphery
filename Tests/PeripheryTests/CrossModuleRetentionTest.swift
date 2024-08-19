import SystemPackage
@testable import TestShared

final class CrossModuleRetentionTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        build(projectPath: FixturesProjectPath)
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
