import Configuration
import SystemPackage
@testable import TestShared

/// Tests for unused import detection.
final class UnusedImportTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        build(projectPath: FixturesProjectPath)
        index(configuration: Configuration())
    }

    func testUnusedImportFalsePositiveForConformanceProvider() {
        // Module D imports A, B, C where:
        // - A provides ConformanceClass and ConformanceProtocol
        // - B provides the conformance (no direct references!)
        // - C provides acceptConformingType function
        //
        // Module B's import should NOT be flagged as unused since it provides the conformance.
        module("UnusedImportFixtureD") {
            self.assertReferenced(.module("UnusedImportFixtureA"))
            self.assertReferenced(.module("UnusedImportFixtureB"))
            self.assertReferenced(.module("UnusedImportFixtureC"))
        }

        module("UnusedImportFixtureA") {
            self.assertReferenced(.class("ConformanceClass"))
            self.assertReferenced(.protocol("ConformanceProtocol"))
        }

        module("UnusedImportFixtureC") {
            self.assertReferenced(.functionFree("acceptConformingType(_:)"))
        }
    }
}
