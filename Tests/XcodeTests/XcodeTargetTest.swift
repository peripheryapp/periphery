import Foundation
import XCTest
import TestShared
@testable import XcodeSupport
@testable import PeripheryKit

class XcodeTargetTest: XCTestCase {
    func testSourceFileInGroupWithoutFolder() throws {
        let project = try! XcodeProject.make(path: iOSProjectPath)
        let target = project.targets.first { $0.name == "iOSProject" }!

        XCTAssertTrue(try target.sourceFiles().contains { $0.relativeTo(ProjectRootPath) == "Tests/XcodeTests/iOSProject/iOSProject/FileInGroupWithoutFolder.swift" })
    }

    func testIsTestTarget() {
        let project = try! XcodeProject.make(path: iOSProjectPath)
        let projectTarget = project.targets.first { $0.name == "iOSProject" }!
        let testTarget = project.targets.first { $0.name == "iOSProjectTests" }!

        XCTAssertFalse(projectTarget.isTestTarget)
        XCTAssertTrue(testTarget.isTestTarget)
    }
}
