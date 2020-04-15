import Foundation
import XCTest
@testable import PeripheryKit

class XcodebuildSettingsParserTest: XCTestCase {
    private static var project: Project!

    private var xcodebuild: Xcodebuild!

    private var project: Project! {
        return XcodebuildSettingsParserTest.project
    }

    override static func setUp() {
        super.setUp()

        project = try! Project.make(path: PeripheryProjectPath)
    }

    override func setUp() {
        super.setUp()

        xcodebuild = Xcodebuild.make()
    }

    func testBuildTargets() {
        let pyKitSettings = try! xcodebuild.buildSettings(for: project, scheme: "Periphery-Package")
        let pyKitParser = XcodebuildSettingsParser(settings: pyKitSettings)

        XCTAssertEqual(pyKitParser.buildTargets(action: "build").sorted(), ["Periphery", "PeripheryKit"])
        XCTAssertEqual(pyKitParser.buildTargets(action: "test").sorted(), ["Periphery", "PeripheryKit", "PeripheryKitTests", "RetentionFixtures", "SyntaxFixtures", "TestEmptyTarget"])

        let pySettings = try! xcodebuild.buildSettings(for: project, scheme: "Periphery")
        let pyParser = XcodebuildSettingsParser(settings: pySettings)

        XCTAssertEqual(pyParser.buildTargets(action: "build"), ["Periphery"])
        // This should really be empty, but SPM adds the test targets to the scheme for some reason.
        XCTAssertEqual(pyParser.buildTargets(action: "test").sorted(), ["Periphery", "PeripheryKitTests"])
    }
}
