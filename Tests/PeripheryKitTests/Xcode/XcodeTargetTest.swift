import Foundation
import XCTest
@testable import PeripheryKit

class XcodeTargetTest: XCTestCase {
    func testSourceFileInGroupWithoutFolder() throws {
        let project = try! XcodeProject.make(path: PeripheryProjectPath)
        let target = project.targets.first { $0.name == "PeripheryKitTests" }!

        XCTAssertTrue(try target.sourceFiles().contains { $0.relativeTo(ProjectRootPath) == "Tests/PeripheryKitTests/Xcode/fileInGroupWithoutFolder.swift" })
    }

    func testIsTestTarget() {
        let project = try! XcodeProject.make(path: PeripheryProjectPath)
        let pyTarget = project.targets.first { $0.name == "Periphery" }!
        let pyKitTarget = project.targets.first { $0.name == "PeripheryKit" }!
        let pyKitTestsTarget = project.targets.first { $0.name == "PeripheryKitTests" }!

        XCTAssertFalse(pyTarget.isTestTarget)
        XCTAssertFalse(pyKitTarget.isTestTarget)
        XCTAssertTrue(pyKitTestsTarget.isTestTarget)
    }
}
