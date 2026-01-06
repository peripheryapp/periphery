import Foundation
import Logger
import SystemPackage
@testable import XcodeSupport
import XCTest

final class XcodebuildSchemesTest: XCTestCase {
    func testParseSchemes() {
        for output in XcodebuildListOutputs {
            let shell = ShellMock(output: output)
            let logger = Logger(quiet: true, verbose: false, colorMode: .never)
            var loadedProjectPaths: Set<FilePath> = []
            let xcodebuild = Xcodebuild(shell: shell, logger: logger)
            let project = try! XcodeProject(path: UIKitProjectPath, loadedProjectPaths: &loadedProjectPaths, xcodebuild: xcodebuild, shell: shell, logger: logger)
            let schemes = try! xcodebuild.schemes(project: project, additionalArguments: [])
            XCTAssertEqual(schemes, ["SchemeA", "SchemeB"])
        }
    }
}
