@testable import TestShared
import XCTest

final class SPMProjectTest: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

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

    func testMacroImport() {
        assertReferenced(.module("SPMProjectKit"))
    }
}
