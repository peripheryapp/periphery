import Foundation
import XCTest
@testable import TargetA

class TestableImportTest: XCTestCase {
    func testRedundant() {
        let cls = RedundantPublicTestableImportClass()
        print(cls.testableProperty ?? "")
    }

    func testNotRedundant() {
        // NotRedundantPublicTestableImportClass is also referenced from MainTarget, and is thus not redundant.
        let cls = NotRedundantPublicTestableImportClass()
        print(cls.testableProperty ?? "")
    }
}
