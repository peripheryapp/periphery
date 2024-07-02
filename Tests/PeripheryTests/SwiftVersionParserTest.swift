import Foundation
import XCTest
import Shared

class SwiftVersionParserTest: XCTestCase {
    func testParse() throws {
        let v1 = try SwiftVersionParser.parse("Apple Swift version 5.4 (swiftlang-1205.0.16.12 clang-1205.0.19.6)\nTarget: x86_64-apple-darwin20.2.0")
        XCTAssertEqual(v1, "5.4")

        let v2 = try SwiftVersionParser.parse("Apple Swift version 5.3.2 (swiftlang-1200.0.45 clang-1200.0.32.28)\nTarget: x86_64-apple-darwin20.2.0")
        XCTAssertEqual(v2, "5.3.2")

        let v3 = try SwiftVersionParser.parse("Swift version 5.4-dev (LLVM e2976fe639d1f50, Swift ce587f0a137bf18)\nTarget: x86_64-apple-darwin20.2.0")
        XCTAssertEqual(v3, "5.4")

        let v4 = try SwiftVersionParser.parse("swift-driver version: 1.26.5 Apple Swift version 5.5 (swiftlang-1300.0.24.13 clang-1300.0.25.10)\nTarget: x86_64-apple-macosx11.0")
        XCTAssertEqual(v4, "5.5")

        let v5 = try SwiftVersionParser.parse("swift-driver version: 1.62.8 Apple Swift version 5.7 (swiftlang-5.7.0.127.4 clang-1400.0.29.50)\nTarget: arm64-apple-macosx12.0")
        XCTAssertEqual(v5, "5.7")
    }
}
