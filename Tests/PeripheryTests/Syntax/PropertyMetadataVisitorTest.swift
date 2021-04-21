import Foundation
import XCTest
import PathKit
import TestShared
@testable import PeripheryKit

class PropertyMetadataVisitorTest: XCTestCase {
    func testPropertyMetadataVisitor() throws {
        let parser = try MultiplexingParser(file: fixturePath)
        let visitor = parser.add(PropertyMetadataVisitor.self)
        parser.parse()
        let results = visitor.resultsByLocation

        let implicitTypeProperty = results[fixtureLocation(line: 8)]!
        let boolProperty = results[fixtureLocation(line: 9)]!
        let optionalBoolProperty = results[fixtureLocation(line: 10)]!
        let arrayLiteralProperty = results[fixtureLocation(line: 11)]!
        let optionalArrayLiteralProperty = results[fixtureLocation(line: 12)]!
        let genericProperty = results[fixtureLocation(line: 13)]!
        let tupleProperty = results[fixtureLocation(line: 14)]!
        let destructuringPropertyA = results[fixtureLocation(line: 15, column: 10)]!
        let destructuringPropertyB = results[fixtureLocation(line: 15, column: 34)]!
        let destructuringPropertyC = results[fixtureLocation(line: 16, column: 10)]!
        let destructuringPropertyD = results[fixtureLocation(line: 17, column: 10)]!
        let destructuringPropertyE = results[fixtureLocation(line: 18, column: 10)]!
        let implicitDestructuringPropertyA = results[fixtureLocation(line: 20, column: 10)]!
        let implicitDestructuringPropertyB = results[fixtureLocation(line: 20, column: 42)]!
        let multipleBindingPropertyA = results[fixtureLocation(line: 21)]!
        let multipleBindingPropertyB = results[fixtureLocation(line: 21, column: 44)]!

        XCTAssertNil(implicitTypeProperty.type)
        XCTAssertNil(implicitTypeProperty.typeLocations)

        XCTAssertEqual(boolProperty.type, "Bool")
        XCTAssertEqual(boolProperty.typeLocations, [fixtureLocation(line: 9, column: 23)])

        XCTAssertEqual(optionalBoolProperty.type, "Bool")
        XCTAssertEqual(optionalBoolProperty.typeLocations, [fixtureLocation(line: 10, column: 31)])

        XCTAssertEqual(arrayLiteralProperty.type, "[CustomType]")
        XCTAssertEqual(arrayLiteralProperty.typeLocations, [fixtureLocation(line: 11, column: 31)])

        XCTAssertEqual(optionalArrayLiteralProperty.type, "[CustomType]")
        XCTAssertEqual(optionalArrayLiteralProperty.typeLocations, [fixtureLocation(line: 12, column: 39)])

        XCTAssertEqual(genericProperty.type, "Set<CustomType>")
        XCTAssertEqual(genericProperty.typeLocations, [fixtureLocation(line: 13, column: 26)])

        XCTAssertEqual(tupleProperty.type, "(Int, String)")
        XCTAssertEqual(tupleProperty.typeLocations, [fixtureLocation(line: 14, column: 24)])

        XCTAssertEqual(destructuringPropertyA.type, "CustomType")
        XCTAssertEqual(destructuringPropertyA.typeLocations, [fixtureLocation(line: 15, column: 60)])

        XCTAssertEqual(destructuringPropertyB.type, "String")
        XCTAssertEqual(destructuringPropertyB.typeLocations, [fixtureLocation(line: 15, column: 72)])

        XCTAssertEqual(destructuringPropertyC.type, "CustomType.NestedType")
        XCTAssertEqual(destructuringPropertyC.typeLocations, [fixtureLocation(line: 19, column: 10), fixtureLocation(line: 19, column: 21)])

        XCTAssertEqual(destructuringPropertyD.type, "CustomType.NestedType.NestedScalar")
        XCTAssertEqual(destructuringPropertyD.typeLocations, [fixtureLocation(line: 19, column: 33), fixtureLocation(line: 19, column: 44), fixtureLocation(line: 19, column: 55)])

        XCTAssertEqual(destructuringPropertyE.type, "Swift.String")
        XCTAssertEqual(destructuringPropertyE.typeLocations, [fixtureLocation(line: 19, column: 69), fixtureLocation(line: 19, column: 75)])

        XCTAssertNil(implicitDestructuringPropertyA.type)
        XCTAssertNil(implicitDestructuringPropertyA.typeLocations)

        XCTAssertNil(implicitDestructuringPropertyB.type)
        XCTAssertNil(implicitDestructuringPropertyB.typeLocations)

        XCTAssertEqual(multipleBindingPropertyA.type, "Int")
        XCTAssertEqual(multipleBindingPropertyA.typeLocations, [fixtureLocation(line: 21, column: 35)])

        XCTAssertEqual(multipleBindingPropertyB.type, "String")
        XCTAssertEqual(multipleBindingPropertyB.typeLocations, [fixtureLocation(line: 21, column: 70)])
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
