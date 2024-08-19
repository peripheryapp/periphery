import Foundation
import Shared
@testable import XcodeSupport
import XCTest

final class XcodebuildBuildProjectTest: XCTestCase {
    private var xcodebuild: Xcodebuild!
    private var project: XcodeProject!

    override func setUp() {
        super.setUp()

        xcodebuild = Xcodebuild(shell: .shared)
        project = try! XcodeProject(path: UIKitProjectPath)
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
