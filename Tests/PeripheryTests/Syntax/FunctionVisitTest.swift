import Foundation
import XCTest
@testable import TestShared
@testable import SourceGraph
@testable import StaticAnalyse

class FunctionVisitTest: XCTestCase {
    private var results: [Location: DeclarationSyntaxVisitor.Result]!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let multiplexingVisitor = try MultiplexingSyntaxVisitor(file: fixturePath)
        let visitor = multiplexingVisitor.add(DeclarationSyntaxVisitor.self)
        multiplexingVisitor.visit()
        results = visitor.resultsByLocation
    }

    func testFunctionWithSimpleReturnType() throws {
        let result = results[fixtureLocation(line: 1)]
        XCTAssertEqual(result?.returnTypeLocations, [fixtureLocation(line: 1, column: 40)])
        XCTAssertTrue(result?.parameterTypeLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericParameterLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericConformanceRequirementLocations.isEmpty ?? false)
    }

    func testFunctionWithTupleReturnType() throws {
        let result = results[fixtureLocation(line: 5)]
        XCTAssertEqual(result?.returnTypeLocations, [
            fixtureLocation(line: 5, column: 40),
            fixtureLocation(line: 5, column: 48)
        ])
        XCTAssertTrue(result?.parameterTypeLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericParameterLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericConformanceRequirementLocations.isEmpty ?? false)
    }

    func testFunctionWithPrefixedReturnType() throws {
        let result = results[fixtureLocation(line: 9)]
        XCTAssertEqual(result?.returnTypeLocations, [
            fixtureLocation(line: 9, column: 42),
            fixtureLocation(line: 9, column: 48)
        ])
        XCTAssertTrue(result?.parameterTypeLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericParameterLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericConformanceRequirementLocations.isEmpty ?? false)
    }

    func testFunctionWithClosureReturnType() throws {
        let result = results[fixtureLocation(line: 13)]
        XCTAssertEqual(result?.returnTypeLocations, [
            fixtureLocation(line: 13, column: 42),
            fixtureLocation(line: 13, column: 50)
        ])
        XCTAssertTrue(result?.parameterTypeLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericParameterLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericConformanceRequirementLocations.isEmpty ?? false)
    }

    func testFunctionWithArguments() throws {
        let result = results[fixtureLocation(line: 18)]
        XCTAssertEqual(result?.parameterTypeLocations, [
            fixtureLocation(line: 18, column: 31),
            fixtureLocation(line: 18, column: 42)
        ])
        XCTAssertTrue(result?.returnTypeLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericParameterLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericConformanceRequirementLocations.isEmpty ?? false)
    }

    func testFunctionWithGenericArguments() throws {
        let result = results[fixtureLocation(line: 20)]
        XCTAssertEqual(result?.parameterTypeLocations, [
            fixtureLocation(line: 20, column: 70)
        ])
        XCTAssertEqual(result?.genericParameterLocations, [
            fixtureLocation(line: 20, column: 37),
            fixtureLocation(line: 20, column: 54)
        ])
        XCTAssertEqual(result?.genericConformanceRequirementLocations, [
            fixtureLocation(line: 20, column: 87)
        ])
        XCTAssertTrue(result?.returnTypeLocations.isEmpty ?? false)
    }

    func testFunctionWithSomeReturnType() throws {
        let result = results[fixtureLocation(line: 23)]
        XCTAssertEqual(result?.returnTypeLocations, [
            fixtureLocation(line: 23, column: 43)
        ])
        XCTAssertTrue(result?.parameterTypeLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericParameterLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericConformanceRequirementLocations.isEmpty ?? false)
    }

    func testInitializerWithArguments() throws {
        let result = results[fixtureLocation(line: 26, column: 5)]
        XCTAssertEqual(result?.parameterTypeLocations, [
            fixtureLocation(line: 26, column: 13),
            fixtureLocation(line: 26, column: 24)
        ])
        XCTAssertTrue(result?.returnTypeLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericParameterLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericConformanceRequirementLocations.isEmpty ?? false)
    }

    func testInitializerWithGenericArguments() throws {
        let result = results[fixtureLocation(line: 30, column: 5)]
        XCTAssertEqual(result?.parameterTypeLocations, [
            fixtureLocation(line: 30, column: 46)
        ])
        XCTAssertEqual(result?.genericParameterLocations, [
            fixtureLocation(line: 30, column: 13),
            fixtureLocation(line: 30, column: 30)
        ])
        XCTAssertEqual(result?.genericConformanceRequirementLocations, [
            fixtureLocation(line: 30, column: 63)
        ])
        XCTAssertTrue(result?.returnTypeLocations.isEmpty ?? false)
    }

    func testSubscriptWithArguments() throws {
        let result = results[fixtureLocation(line: 34, column: 5)]
        XCTAssertEqual(result?.parameterTypeLocations, [
            fixtureLocation(line: 34, column: 18),
            fixtureLocation(line: 34, column: 26)
        ])
        XCTAssertEqual(result?.returnTypeLocations, [
            fixtureLocation(line: 34, column: 37)
        ])
        XCTAssertTrue(result?.genericParameterLocations.isEmpty ?? false)
        XCTAssertTrue(result?.genericConformanceRequirementLocations.isEmpty ?? false)
    }

    func testSubscriptWithGenericArguments() throws {
        let result = results[fixtureLocation(line: 35, column: 5)]
        XCTAssertEqual(result?.parameterTypeLocations, [
            fixtureLocation(line: 35, column: 51)
        ])
        XCTAssertEqual(result?.returnTypeLocations, [
            fixtureLocation(line: 35, column: 62)
        ])
        XCTAssertEqual(result?.genericParameterLocations, [
            fixtureLocation(line: 35, column: 18),
            fixtureLocation(line: 35, column: 35)
        ])
        XCTAssertEqual(result?.genericConformanceRequirementLocations, [
            fixtureLocation(line: 35, column: 75)
        ])
    }

    // MARK: - Private

    private var fixturePath: SourceFile {
        let path = ProjectRootPath.appending( "Tests/Fixtures/DeclarationVisitorFixtures/FunctionFixture.swift")
        return SourceFile(path: path, modules: ["DeclarationVisitorFixtures"])
    }

    private func fixtureLocation(line: Int, column: Int = 6) -> Location {
        Location(file: fixturePath, line: line, column: column)
    }
}
