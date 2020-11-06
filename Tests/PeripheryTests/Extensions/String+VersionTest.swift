import Foundation
import XCTest

class StringVersionTest: XCTestCase {
    func testVersion() {
        XCTAssertTrue("9.3".isVersion(lessThan: "10.0"))
        XCTAssertTrue("9.3.1".isVersion(lessThan: "10.0"))
        XCTAssertTrue("9.3.1".isVersion(lessThan: "9.3.2"))
        XCTAssertTrue("9.3.3".isVersion(greaterThan: "9.3.2"))

        XCTAssertFalse("9.3.1".isVersion(equalTo: "9.3"))
        XCTAssertFalse("9.3".isVersion(equalTo: "10.0"))
    }
}
