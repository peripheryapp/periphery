import Foundation
import XCTest
import SwiftSyntax
import SwiftParser
@testable import TestShared
@testable import PeripheryKit
@testable import SourceGraph

class TypeSyntaxInspectorTest: XCTestCase {
    private var results: [Location: TypeSyntaxInspectorTestVisitor.Result]!

    override func setUpWithError() throws {
        super.setUp()
        let visitor = try TypeSyntaxInspectorTestVisitor(file: fixturePath)
        visitor.visit()
        results = visitor.results
    }

    func testSimpleType() {
        let simpleType = results[fixtureLocation(line: 3, column: 17)]
        XCTAssertEqual(simpleType?.type, "String")
        XCTAssertEqual(simpleType?.locations, [fixtureLocation(line: 3, column: 17)])
    }

    func testOptionalType() {
        let optionalType = results[fixtureLocation(line: 4, column: 19)]
        XCTAssertEqual(optionalType?.type, "String")
        XCTAssertEqual(optionalType?.locations, [fixtureLocation(line: 4, column: 19)])
    }

    func testMemberType() {
        let memberType = results[fixtureLocation(line: 5, column: 17)]
        XCTAssertEqual(memberType?.type, "Swift.String")
        XCTAssertEqual(memberType?.locations, [
            fixtureLocation(line: 5, column: 17),
            fixtureLocation(line: 5, column: 23)
        ])
    }

    func testTupleType() {
        let tupleType = results[fixtureLocation(line: 6, column: 16)]
        XCTAssertEqual(tupleType?.type, "(String, Int)")
        XCTAssertEqual(tupleType?.locations, [
            fixtureLocation(line: 6, column: 17),
            fixtureLocation(line: 6, column: 25)
        ])
    }

    func testDictionaryType() {
        let result = results[fixtureLocation(line: 7, column: 21)]
        XCTAssertEqual(result?.type, "[String: Int]")
        XCTAssertEqual(result?.locations, [
            fixtureLocation(line: 7, column: 22),
            fixtureLocation(line: 7, column: 30)
        ])
    }

    func testArrayType() {
        let result = results[fixtureLocation(line: 8, column: 16)]
        XCTAssertEqual(result?.type, "[String]")
        XCTAssertEqual(result?.locations, [fixtureLocation(line: 8, column: 17)])
    }

    func testFunctionSimpleReturnType() {
        let functionSimpleReturnType = results[fixtureLocation(line: 9, column: 36)]
        XCTAssertEqual(functionSimpleReturnType?.type, "String")
        XCTAssertEqual(functionSimpleReturnType?.locations, [fixtureLocation(line: 9, column: 36)])
    }

    func testFunctionClosureReturnType() {
        let functionClosureReturnType = results[fixtureLocation(line: 10, column: 37)]
        XCTAssertEqual(functionClosureReturnType?.type, "(Int) -> String")
        XCTAssertEqual(functionClosureReturnType?.locations, [
            fixtureLocation(line: 10, column: 38),
            fixtureLocation(line: 10, column: 46)
        ])
    }

    func testFunctionArgumentType() {
        let functionArgumentTypeA = results[fixtureLocation(line: 14, column: 30)]
        XCTAssertEqual(functionArgumentTypeA?.type, "String")
        XCTAssertEqual(functionArgumentTypeA?.locations, [fixtureLocation(line: 14, column: 30)])

        let functionArgumentTypeB = results[fixtureLocation(line: 14, column: 41)]
        XCTAssertEqual(functionArgumentTypeB?.type, "Int")
        XCTAssertEqual(functionArgumentTypeB?.locations, [fixtureLocation(line: 14, column: 41)])
    }

    func testGenericFunction() {
        let genericFunctionArgument = results[fixtureLocation(line: 15, column: 58)]
        XCTAssertEqual(genericFunctionArgument?.type, "T.Type")
        XCTAssertEqual(genericFunctionArgument?.locations, [
            fixtureLocation(line: 15, column: 58)
        ])

        let genericParamClause = results[fixtureLocation(line: 15, column: 25)]
        XCTAssertEqual(genericParamClause?.type, "StringProtocol & AnyObject")
        XCTAssertEqual(genericParamClause?.locations, [
            fixtureLocation(line: 15, column: 25),
            fixtureLocation(line: 15, column: 42)
        ])

        let genericWhereClause = results[fixtureLocation(line: 15, column: 75)]
        XCTAssertEqual(genericWhereClause?.type, "RawRepresentable")
        XCTAssertEqual(genericWhereClause?.locations, [fixtureLocation(line: 15, column: 75)])
    }

    func testFunctionSomeReturnType() {
        let functionSimpleReturnType = results[fixtureLocation(line: 17, column: 33)]
        XCTAssertEqual(functionSimpleReturnType?.type, "StringProtocol")
        XCTAssertEqual(functionSimpleReturnType?.locations, [fixtureLocation(line: 17, column: 33)])
    }

    // MARK: - Private

    private var fixturePath: SourceFile {
        let path = FixturesProjectPath.appending( "Sources/TypeSyntaxInspectorFixtures/TypeSyntaxInspectorFixture.swift")
        return SourceFile(path: path, modules: ["TypeSyntaxInspectorFixtures"])
    }

    private func fixtureLocation(line: Int, column: Int = 1) -> Location {
        Location(file: fixturePath, line: line, column: column)
    }
}

private class TypeSyntaxInspectorTestVisitor: SyntaxVisitor {
    private let syntax: SourceFileSyntax
    private let locationConverter: SourceLocationConverter
    private let sourceLocationBuilder: SourceLocationBuilder
    private let typeSyntaxInspector: TypeSyntaxInspector

    typealias Result = (type: String, locations: [Location])
    var results: [Location: Result] = [:]

    init(file: SourceFile) throws {
        let source = try String(contentsOf: file.path.url)
        self.syntax = Parser.parse(source: source)
        self.locationConverter = .init(fileName: file.path.string, tree: syntax)
        self.sourceLocationBuilder = .init(file: file, locationConverter: locationConverter)
        self.typeSyntaxInspector = .init(sourceLocationBuilder: sourceLocationBuilder)
        super.init(viewMode: .sourceAccurate)
    }

    func visit() {
        walk(syntax)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            if let typeSyntax = binding.typeAnnotation?.type {
                addResult(for: typeSyntax)
            }
        }

        return .skipChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let returnTypeSyntax = node.signature.returnClause?.type {
            if let someTypeSyntax = returnTypeSyntax.as(SomeOrAnyTypeSyntax.self) {
                addResult(for: someTypeSyntax.constraint)
            } else {
                addResult(for: returnTypeSyntax)
            }
        }

        for functionParameterSyntax in node.signature.parameterClause.parameters {
            addResult(for: functionParameterSyntax.type)
        }

        if let genericParameterList = node.genericParameterClause?.parameters {
            for param in genericParameterList  {
                if let inheritedType = param.inheritedType {
                    addResult(for: inheritedType)
                }
            }
        }

        if let requirementList = node.genericWhereClause?.requirements {
            for requirement in requirementList {
                if let conformanceRequirementType = requirement.requirement.as(ConformanceRequirementSyntax.self) {
                    addResult(for: conformanceRequirementType.rightType)
                }
            }
        }

        return .skipChildren
    }

    private func addResult(for typeSyntax: TypeSyntax) {
        let location = sourceLocationBuilder.location(at: typeSyntax.positionAfterSkippingLeadingTrivia)
        let type = typeSyntaxInspector.type(for: typeSyntax)
        let locations = typeSyntaxInspector.typeLocations(for: typeSyntax)
        results[location] = (type, locations.sorted())
    }
}
