import Foundation
import XCTest
@testable import PeripheryKit

class ScanCommandTest: XCTestCase {
    func testSingleSchemes() throws {
        let args = ["--schemes", "Periphery Kit"]
        let options = try ScanCommand.parse(args)

        XCTAssertEqual(options.schemes, ["Periphery Kit"])
    }

    func testMultipleSchemes() throws {
        let args = ["--schemes", "periphery,Periphery Kit"]
        let options = try ScanCommand.parse(args)

        XCTAssertEqual(options.schemes, ["periphery", "Periphery Kit"])
    }

    func testSingleTarget() throws {
        let args = ["--targets", "Periphery Kit"]
        let options = try ScanCommand.parse(args)

        XCTAssertEqual(options.targets, ["Periphery Kit"])
    }

    func testMultipleTargets() throws {
        let args = ["--targets", "periphery,Periphery Kit"]
        let options = try ScanCommand.parse(args)

        XCTAssertEqual(options.targets, ["periphery", "Periphery Kit"])
    }

    func testExcludeOptions() throws {
        let args = ["--report-exclude", "/path/to/a.swift|/path with spaces/{a,b}.swift|/path/*.swift", "--index-exclude", "*.swift"]
        let options = try ScanCommand.parse(args)

        XCTAssertEqual(options.reportExclude, ["/path/to/a.swift", "/path with spaces/{a,b}.swift", "/path/*.swift"])
        XCTAssertEqual(options.indexExclude, ["*.swift"])
    }
}
