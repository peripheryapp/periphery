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

        project = try! XcodeProject.make(path: iOSProjectPath)
    }

    override func setUp() {
        super.setUp()

        xcodebuild = Xcodebuild.make()
    }

    func testBuildTargets() {
        let settings = try! xcodebuild.buildSettings(for: project, scheme: "iOSProject")
        let parser = XcodebuildSettingsParser(settings: settings)

        XCTAssertEqual(parser.buildTargets(action: "build").sorted(), ["iOSProject"])
        XCTAssertEqual(parser.buildTargets(action: "test").sorted(), ["iOSProject", "iOSProjectTests"])
    }
}
