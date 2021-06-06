import Foundation
import XCTest
import TestShared
@testable import XcodeSupport
@testable import PeripheryKit

class XcodeTargetTest: XCTestCase {
    func testSourceFileInGroupWithoutFolder() throws {
        let project = try! XcodeProject.make(path: UIKitProjectPath)
        let target = project.targets.first { $0.name == "UIKitProject" }!

        XCTAssertTrue(try target.sourceFiles().contains { $0.relativeTo(ProjectRootPath) == "Tests/XcodeTests/UIKitProject/UIKitProject/FileInGroupWithoutFolder.swift" })
    }

    func testIsTestTarget() {
        let project = try! XcodeProject.make(path: UIKitProjectPath)
        let projectTarget = project.targets.first { $0.name == "UIKitProject" }!
        let testTarget = project.targets.first { $0.name == "UIKitProjectTests" }!

        XCTAssertFalse(projectTarget.isTestTarget)
        XCTAssertTrue(testTarget.isTestTarget)
    }
}
