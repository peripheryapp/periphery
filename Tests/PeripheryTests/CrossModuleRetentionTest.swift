import Configuration
import SystemPackage
@testable import TestShared

final class CrossModuleRetentionTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        build(projectPath: FixturesProjectPath)
        index(configuration: Configuration())
    }

    func testCrossModuleInheritanceWithSameName() {
        module("CrossModuleRetentionFixtures") {
            self.assertReferenced(.class("FixtureClass129"))
        }

        module("CrossModuleRetentionSupportFixtures") {
            self.assertReferenced(.class("FixtureClass129"))
        }
    }

    func testCrossModuleLocalizedStringOverridesAreTreatedAsSingleSourceDeclaration() {
        assertNoUnusedResult(.varInstance("title", line: 15), inModule: "GeneratedLocalizedStringPrimaryFixtures")
        assertNoUnusedResult(.varInstance("title", line: 20), inModule: "GeneratedLocalizedStringPrimaryFixtures")
        assertNoUnusedResult(.varInstance("toast", line: 29), inModule: "GeneratedLocalizedStringPrimaryFixtures")

        assertNoUnusedResult(.varInstance("title", line: 15), inModule: "GeneratedLocalizedStringDuplicateFixtures")
        assertNoUnusedResult(.varInstance("title", line: 20), inModule: "GeneratedLocalizedStringDuplicateFixtures")
        assertNoUnusedResult(.varInstance("toast", line: 29), inModule: "GeneratedLocalizedStringDuplicateFixtures")
    }
}
