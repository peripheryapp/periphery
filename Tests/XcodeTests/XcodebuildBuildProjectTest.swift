import Foundation
import Shared
@testable import XcodeSupport
import XCTest

final class XcodebuildBuildProjectTest: XCTestCase {
    private var xcodebuild: Xcodebuild!
    private var project: XcodeProject!

    override func setUp() {
        super.setUp()

        let configuration = Configuration()
        let logger = Logger(configuration: configuration)
        let shell = Shell(logger: logger)
        xcodebuild = Xcodebuild(shell: shell, logger: logger)
        project = try! XcodeProject(path: UIKitProjectPath, xcodebuild: xcodebuild, shell: shell, logger: logger)
    }

    override func tearDown() {
        xcodebuild = nil
        project = nil
        super.tearDown()
    }

    func testBuildSchemeWithWhitespace() throws {
        let scheme = "Scheme With Spaces"
        try xcodebuild.build(project: project, scheme: scheme, allSchemes: [scheme])
    }
}
