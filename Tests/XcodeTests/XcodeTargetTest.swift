import Foundation
@testable import TestShared
@testable import XcodeSupport
import XCTest

final class XcodeTargetTest: XCTestCase {
    func testSourceFileInGroupWithoutFolder() throws {
        let project = try! XcodeProject(path: UIKitProjectPath)
        let target = project.targets.first { $0.name == "UIKitProject" }!
        try target.identifyFiles()

        XCTAssertTrue(target.files(kind: .swift).contains {
            $0.relativeTo(ProjectRootPath).string == "Tests/XcodeTests/UIKitProject/UIKitProject/FileInGroupWithoutFolder.swift"
        })
    }

    func testIsTestTarget() {
        let project = try! XcodeProject(path: UIKitProjectPath)
        let projectTarget = project.targets.first { $0.name == "UIKitProject" }!
        let testTarget = project.targets.first { $0.name == "UIKitProjectTests" }!

        XCTAssertFalse(projectTarget.isTestTarget)
        XCTAssertTrue(testTarget.isTestTarget)
    }
}
