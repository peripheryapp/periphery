import Foundation
import XCTest
import PathKit
import TestShared
@testable import PeripheryKit

class PropertyTypeParserTest: XCTestCase {
    func testPropertyTypeParser() throws {
        let boolPropertyLocation = fixtureLocation(line: 4)
        let optionalBoolPropertyLocation = fixtureLocation(line: 5)
        let arrayLiteralPropertyLocation = fixtureLocation(line: 6)
        let optionalArrayLiteralPropertyLocation = fixtureLocation(line: 7)
        let genericPropertyLocation = fixtureLocation(line: 8)

        let locations: [SourceLocation: String] = [
            boolPropertyLocation: "boolProperty",
            optionalBoolPropertyLocation: "optionalBoolProperty",
            arrayLiteralPropertyLocation: "arrayLiteralProperty",
            optionalArrayLiteralPropertyLocation: "optionalArrayLiteralProperty",
            genericPropertyLocation: "genericProperty",
        ]

        let typesByLocation = try PropertyTypeParser(file: fixturePath, propertyNamesByLocation: locations).parse()

        XCTAssertEqual(typesByLocation[boolPropertyLocation] ?? "", "Bool")
        XCTAssertEqual(typesByLocation[optionalBoolPropertyLocation] ?? "", "Bool")
        XCTAssertEqual(typesByLocation[arrayLiteralPropertyLocation] ?? "", "[CustomType]")
        XCTAssertEqual(typesByLocation[optionalArrayLiteralPropertyLocation] ?? "", "[CustomType]")
        XCTAssertEqual(typesByLocation[genericPropertyLocation] ?? "", "Set<CustomType>")
    }

    // MARK: - Private

    private var fixturePath: Path {
        #if os(macOS)
        let testName = String(name.split(separator: " ").last!).replacingOccurrences(of: "]", with: "")
        #else
        let testName = String(name.split(separator: ".", maxSplits: 1).last!)
        #endif

        return ProjectRootPath + "Tests/SyntaxFixtures/\(testName).swift"
    }

    private func fixtureLocation(line: Int, column: Int = 9) -> SourceLocation {
        SourceLocation(file: fixturePath, line: Int64(line), column: Int64(column))
    }
}
