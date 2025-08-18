import SPMProjectKit
import XCTest

class MacroImportTests: XCTestCase {
    func testMacro() {
        // This is the only reference to SPMProjectKit.
        _ = MockedProtocolMock.self
    }
}
