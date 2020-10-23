import Foundation
import XCTest
@testable import PeripheryKit

class SchemeTest: XCTestCase {
    private var scheme: Scheme!

    override func setUp() {
        let project = try! Project.make(path: PeripheryProjectPath)
        scheme = try! Scheme.make(project: project, name: "Periphery-Package")
    }

    func testTargets() throws {
        XCTAssertEqual(try scheme.buildTargets().sorted(), ["Periphery", "PeripheryKit", "RetentionFixturesCrossModule"])
        XCTAssertEqual(try scheme.testTargets().sorted(), ["Periphery", "PeripheryKit", "PeripheryKitTests", "RetentionFixtures", "RetentionFixturesCrossModule", "SyntaxFixtures", "TestEmptyTarget"])
    }
}
