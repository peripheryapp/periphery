import Foundation
import XCTest
@testable import XcodeSupport
@testable import PeripheryKit

class XcodeSchemeTest: XCTestCase {
    private var scheme: XcodeScheme!

    override func setUp() {
        let project = try! XcodeProject.make(path: UIKitProjectPath)
        scheme = try! XcodeScheme.make(project: project, name: "UIKitProject")
    }

    func testTargets() throws {
        XCTAssertEqual(try scheme.testTargets().sorted(), ["UIKitProject", "UIKitProjectTests"])
    }
}
