import Foundation
import XCTest
import Commandant
@testable import PeripheryKit

class ScanCommandTest: XCTestCase {
    func testSingleSchemes() {
        let args = ["./.build/debug/periphery", "scan", "--schemes", "Periphery Kit"]
        let commandMode = CommandMode.arguments(ArgumentParser(args))
        let result = ScanOptions.evaluate(commandMode)

        guard case let .success(options) = result else {
            XCTFail("Failed to parse options.")
            return
        }

        XCTAssertEqual(options.schemes, ["Periphery Kit"])
    }

    func testMultipleSchemes() {
        let args = ["./.build/debug/periphery", "scan", "--schemes", "periphery,Periphery Kit"]
        let commandMode = CommandMode.arguments(ArgumentParser(args))
        let result = ScanOptions.evaluate(commandMode)

        guard case let .success(options) = result else {
            XCTFail("Failed to parse options.")
            return
        }

        XCTAssertEqual(options.schemes, ["periphery", "Periphery Kit"])
    }

    func testSingleTarget() {
        let args = ["./.build/debug/periphery", "scan", "--targets", "Periphery Kit"]
        let commandMode = CommandMode.arguments(ArgumentParser(args))
        let result = ScanOptions.evaluate(commandMode)

        guard case let .success(options) = result else {
            XCTFail("Failed to parse options.")
            return
        }

        XCTAssertEqual(options.targets, ["Periphery Kit"])
    }

    func testMultipleTargets() {
        let args = ["./.build/debug/periphery", "scan", "--targets", "periphery,Periphery Kit"]
        let commandMode = CommandMode.arguments(ArgumentParser(args))
        let result = ScanOptions.evaluate(commandMode)

        guard case let .success(options) = result else {
            XCTFail("Failed to parse options.")
            return
        }

        XCTAssertEqual(options.targets, ["periphery", "Periphery Kit"])
    }

    func testExcludeOptions() {
        let args = ["./.build/debug/periphery", "scan", "--report-exclude", "/path/to/a.swift|/path with spaces/{a,b}.swift|/path/*.swift", "--index-exclude", "*.swift"]
        let commandMode = CommandMode.arguments(ArgumentParser(args))
        let result = ScanOptions.evaluate(commandMode)

        guard case let .success(options) = result else {
            XCTFail("Failed to parse options.")
            return
        }

        XCTAssertEqual(options.reportExclude, ["/path/to/a.swift", "/path with spaces/{a,b}.swift", "/path/*.swift"])
        XCTAssertEqual(options.indexExclude, ["*.swift"])
    }
}
