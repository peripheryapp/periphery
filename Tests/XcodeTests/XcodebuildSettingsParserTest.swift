import Foundation
import XCTest
@testable import XcodeSupport
@testable import PeripheryKit

class XcodebuildSettingsParserTest: XCTestCase {
    private static var project: XcodeProject!

    private var xcodebuild: Xcodebuild!

    private var project: XcodeProject! {
        return XcodebuildSettingsParserTest.project
    }

    override static func setUp() {
        super.setUp()

        project = try! XcodeProject(path: UIKitProjectPath)
    }

    override func setUp() {
        super.setUp()

        xcodebuild = Xcodebuild()
    }

    func testBuildTargets() {
        let settings = try! xcodebuild.buildSettings(for: project, scheme: "UIKitProject")
        let parser = XcodebuildSettingsParser(settings: settings)

        XCTAssertEqual(parser.buildTargets(action: "build").sorted(), ["UIKitProject"])
        XCTAssertEqual(parser.buildTargets(action: "test").sorted(), ["UIKitProject", "UIKitProjectTests"])
    }
}
