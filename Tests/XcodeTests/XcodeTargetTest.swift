import Foundation
import XCTest
@testable import TestShared
@testable import XcodeSupport

class XcodeTargetTest: XCTestCase {
    func testSourceFileInGroupWithoutFolder() throws {
        let project = try! XcodeProject(path: UIKitProjectPath)
        let target = project.targets.first { $0.name == "UIKitProject" }!
        try target.identifyFiles()

        XCTAssertTrue(target.files(kind: .interfaceBuilder).contains {
            $0.relativeTo(ProjectRootPath).string == "Tests/XcodeTests/UIKitProject/UIKitProject/FileInGroupWithoutFolder.xib"
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
