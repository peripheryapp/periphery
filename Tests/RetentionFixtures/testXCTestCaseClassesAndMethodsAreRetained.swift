import Foundation
import XCTest

class FixtureClass34: XCTestCase {
    override static func setUp() {
        super.setUp()
    }

    override func setUp() {
        super.setUp()
    }

    func testSomething() {}
}

class FixtureClass34Subclass: FixtureClass34 {
    func testSubclass() {}
}
