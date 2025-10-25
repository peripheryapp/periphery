import Foundation
@testable import SourceGraph
@testable import SyntaxAnalysis
@testable import TestShared
import XCTest

final class PropertyVisitTest: XCTestCase {
    private var results: [Location: DeclarationSyntaxVisitor.Result]!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let multiplexingVisitor = try MultiplexingSyntaxVisitor(file: fixturePath)
        let visitor = multiplexingVisitor.add(DeclarationSyntaxVisitor.self)
        multiplexingVisitor.visit()
        results = visitor.resultsByLocation
    }

    override func tearDown() {
        results = nil
        super.tearDown()
    }

    func testImplicitType() {
        let result = results[fixtureLocation(line: 8)]!
        XCTAssertNil(result.variableType)
        XCTAssertTrue(result.variableTypeLocations.isEmpty)
    }

    func testSimpleType() {
        let result = results[fixtureLocation(line: 9)]!
        XCTAssertEqual(result.variableType, "Bool")
        XCTAssertEqual(result.variableTypeLocations, [fixtureLocation(line: 9, column: 23)])
    }

    func testOptionalType() {
        let result = results[fixtureLocation(line: 10)]!
        XCTAssertEqual(result.variableType, "Bool")
        XCTAssertEqual(result.variableTypeLocations, [fixtureLocation(line: 10, column: 31)])
    }

    func testLiteralType() {
        let result = results[fixtureLocation(line: 11)]!
        XCTAssertEqual(result.variableType, "[CustomType]")
        XCTAssertEqual(result.variableTypeLocations, [fixtureLocation(line: 11, column: 32)])
    }

    func testOptionalLiteralType() {
        let result = results[fixtureLocation(line: 12)]!
        XCTAssertEqual(result.variableType, "[CustomType]")
        XCTAssertEqual(result.variableTypeLocations, [fixtureLocation(line: 12, column: 40)])
    }

    func testGenericType() {
        let result = results[fixtureLocation(line: 13)]!
        XCTAssertEqual(result.variableType, "Set<CustomType>")
        XCTAssertEqual(result.variableTypeLocations, [
            fixtureLocation(line: 13, column: 26),
            fixtureLocation(line: 13, column: 30),
        ])
    }

    func testTupleType() {
        let result = results[fixtureLocation(line: 14)]!
        XCTAssertEqual(result.variableType, "(Int, String)")
        XCTAssertEqual(result.variableTypeLocations, [
            fixtureLocation(line: 14, column: 25),
            fixtureLocation(line: 14, column: 30),
        ])
    }

    func testDestructuring() {
        let propertyA = results[fixtureLocation(line: 15, column: 10)]!
        let propertyB = results[fixtureLocation(line: 15, column: 34)]!
        let propertyC = results[fixtureLocation(line: 16, column: 10)]!
        let propertyD = results[fixtureLocation(line: 17, column: 10)]!
        let propertyE = results[fixtureLocation(line: 18, column: 10)]!

        XCTAssertEqual(propertyA.variableType, "CustomType")
        XCTAssertEqual(propertyA.variableTypeLocations, [fixtureLocation(line: 15, column: 60)])

        XCTAssertEqual(propertyB.variableType, "String")
        XCTAssertEqual(propertyB.variableTypeLocations, [fixtureLocation(line: 15, column: 72)])

        XCTAssertEqual(propertyC.variableType, "CustomType.NestedType")
        XCTAssertEqual(propertyC.variableTypeLocations, [
            fixtureLocation(line: 19, column: 10),
            fixtureLocation(line: 19, column: 21),
        ])

        XCTAssertEqual(propertyD.variableType, "CustomType.NestedType.NestedScalar")
        XCTAssertEqual(propertyD.variableTypeLocations, [fixtureLocation(line: 19, column: 33), fixtureLocation(line: 19, column: 44), fixtureLocation(line: 19, column: 55)])

        XCTAssertEqual(propertyE.variableType, "Swift.String")
        XCTAssertEqual(propertyE.variableTypeLocations, [fixtureLocation(line: 19, column: 69), fixtureLocation(line: 19, column: 75)])
    }

    func testImplicitDestructuring() {
        let propertyA = results[fixtureLocation(line: 20, column: 10)]!
        let propertyB = results[fixtureLocation(line: 20, column: 42)]!

        XCTAssertNil(propertyA.variableType)
        XCTAssertTrue(propertyA.variableTypeLocations.isEmpty)

        XCTAssertNil(propertyB.variableType)
        XCTAssertTrue(propertyB.variableTypeLocations.isEmpty)
    }

    func testMultipleBindings() {
        let propertyA = results[fixtureLocation(line: 21)]!
        let propertyB = results[fixtureLocation(line: 21, column: 44)]!

        XCTAssertEqual(propertyA.variableType, "Int")
        XCTAssertEqual(propertyA.variableTypeLocations, [fixtureLocation(line: 21, column: 35)])

        XCTAssertEqual(propertyB.variableType, "String")
        XCTAssertEqual(propertyB.variableTypeLocations, [fixtureLocation(line: 21, column: 70)])
    }

    func testSimpleTypeWithComment() {
        let result = results[fixtureLocation(line: 22)]!
        XCTAssertEqual(result.variableType, "Bool")
        XCTAssertEqual(result.variableTypeLocations, [fixtureLocation(line: 22, column: 32)])
    }

    // MARK: - Private

    private var fixturePath: SourceFile {
        let path = FixturesProjectPath.appending("Sources/DeclarationVisitorFixtures/PropertyFixture.swift")
        return SourceFile(path: path, modules: ["DeclarationVisitorFixtures"])
    }

    private func fixtureLocation(line: Int, column: Int = 9) -> Location {
        Location(file: fixturePath, line: line, column: column)
    }
}
