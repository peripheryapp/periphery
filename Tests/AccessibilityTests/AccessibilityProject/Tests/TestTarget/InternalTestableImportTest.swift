import Foundation
import XCTest
@testable import TargetA

class InternalTestableImportTest: XCTestCase {
    func testInternalAccess() {
        // Access internal declarations via @testable import
        let obj1 = InternalUsedOnlyInTest()
        obj1.testOnlyMethod()

        let obj2 = InternalUsedInBoth()
        obj2.sharedMethod()
    }
}
