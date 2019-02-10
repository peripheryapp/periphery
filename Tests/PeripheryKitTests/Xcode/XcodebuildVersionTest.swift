import Foundation
import XCTest
@testable import PeripheryKit

class XcodebuildVersionTest: XCTestCase {
    func testParse() {
        let version = "Xcode 10.0\nBuild version 10L201y"
        XCTAssertEqual(XcodebuildVersion.parse(version), "10.0")
    }
}
