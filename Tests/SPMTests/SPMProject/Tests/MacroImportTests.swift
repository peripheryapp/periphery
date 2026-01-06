import SPMProjectKit
import XCTest

final class MacroImportTests: XCTestCase {
    func testMacro() {
        // This is the only reference to SPMProjectKit.
        _ = MockedProtocolMock.self
    }
}
