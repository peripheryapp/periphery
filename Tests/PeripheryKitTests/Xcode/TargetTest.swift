import Foundation
import XCTest
@testable import PeripheryKit

class TargetTest: XCTestCase {
    func testSourceFileInGroupWithoutFolder() throws {
        let project = try! Project.make(path: PeripheryProjectPath)
        let target = project.targets.first { $0.name == "PeripheryKitTests" }!

        XCTAssertTrue(try target.sourceFiles().contains { $0.path.relativeTo(ProjectRootPath) == "Tests/PeripheryKitTests/Xcode/fileInGroupWithoutFolder.swift" })
    }

    func testModuleName() {
        let project = try! Project.make(path: PeripheryProjectPath)

        let pyTarget = project.targets.first { $0.name == "Periphery" }!
        try! pyTarget.identifyModuleName()

        let pyKitTarget = project.targets.first { $0.name == "PeripheryKit" }!
        try! pyKitTarget.identifyModuleName()

        let pyKitTestsTarget = project.targets.first { $0.name == "PeripheryKitTests" }!
        try! pyKitTestsTarget.identifyModuleName()

        XCTAssertEqual(pyTarget.moduleName, "Periphery")
        XCTAssertEqual(pyKitTarget.moduleName, "PeripheryKit")
        XCTAssertEqual(pyKitTestsTarget.moduleName, "PeripheryKitTests")
    }

    func testIsTestTarget() {
        let project = try! Project.make(path: PeripheryProjectPath)
        let pyTarget = project.targets.first { $0.name == "Periphery" }!
        let pyKitTarget = project.targets.first { $0.name == "PeripheryKit" }!
        let pyKitTestsTarget = project.targets.first { $0.name == "PeripheryKitTests" }!

        XCTAssertFalse(pyTarget.isTestTarget)
        XCTAssertFalse(pyKitTarget.isTestTarget)
        XCTAssertTrue(pyKitTestsTarget.isTestTarget)
    }
}
