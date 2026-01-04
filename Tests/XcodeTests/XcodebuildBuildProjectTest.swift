import Foundation
import Logger
import Shared
import SystemPackage
@testable import XcodeSupport
import XCTest

final class XcodebuildBuildProjectTest: XCTestCase {
    private var xcodebuild: Xcodebuild!
    private var project: XcodeProject!

    override func setUp() {
        super.setUp()

        let logger = Logger(quiet: true, verbose: false, coloredOutputEnabled: false)
        let shell = ShellImpl(logger: logger)
        var loadedProjectPaths: Set<FilePath> = []
        xcodebuild = Xcodebuild(shell: shell, logger: logger)
        project = try! XcodeProject(path: UIKitProjectPath, loadedProjectPaths: &loadedProjectPaths, xcodebuild: xcodebuild, shell: shell, logger: logger)
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
