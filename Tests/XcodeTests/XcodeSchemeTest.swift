import Foundation
import XCTest
@testable import XcodeSupport
@testable import PeripheryKit

class XcodeSchemeTest: XCTestCase {
    private var scheme: XcodeScheme!

    override func setUp() {
        let project = try! XcodeProject.make(path: iOSProjectPath)
        scheme = try! XcodeScheme.make(project: project, name: "iOSProject")
    }

    func testTargets() throws {
        XCTAssertEqual(try scheme.testTargets().sorted(), ["iOSProject", "iOSProjectTests"])
    }
}
