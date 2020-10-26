import Foundation
import XCTest
@testable import PeripheryKit

class XcodeSchemeTest: XCTestCase {
    private var scheme: XcodeScheme!

    override func setUp() {
        let project = try! XcodeProject.make(path: PeripheryProjectPath)
        scheme = try! XcodeScheme.make(project: project, name: "Periphery-Package")
    }

    func testTargets() throws {
        XCTAssertEqual(try scheme.buildTargets().sorted(), ["Periphery", "PeripheryKit", "RetentionFixturesCrossModule"])
        XCTAssertEqual(try scheme.testTargets().sorted(), ["Periphery", "PeripheryKit", "PeripheryKitTests", "RetentionFixtures", "RetentionFixturesCrossModule", "SyntaxFixtures", "TestEmptyTarget"])
    }
}
