import Foundation
@testable import XcodeSupport
import XCTest

final class XcodebuildSchemesTest: XCTestCase {
    private var shell: ShellMock!
    private var xcodebuild: Xcodebuild!
    private var project: XcodeProject!

    override func setUp() {
        super.setUp()

        shell = ShellMock()
        xcodebuild = Xcodebuild(shell: shell)
        project = try! XcodeProject(path: UIKitProjectPath)
    }

    override func tearDown() {
        shell = nil
        xcodebuild = nil
        project = nil
        super.tearDown()
    }

    func testParseSchemes() {
        for output in XcodebuildListOutputs {
            shell.output = output
            let schemes = try! xcodebuild.schemes(project: project, additionalArguments: [])
            XCTAssertEqual(schemes, ["SchemeA", "SchemeB"])
        }
    }
}
