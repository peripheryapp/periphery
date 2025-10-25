import Foundation
@testable import SourceGraph
@testable import SyntaxAnalysis
@testable import TestShared
import XCTest

final class UnusedParameterTest: XCTestCase {
    func testSimpleUnused() {
        analyze()
        assertUnused("param", in: "myFunc(param:)")
    }

    func testShadowed() {
        analyze()
        assertUnused("param", in: "myFunc1(param:)")
        assertUnused("param", in: "myFunc2(param:)")
        assertUnused("param", in: "myFunc3(param:)")
    }

    func testShadowedAfterUse() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
    }

    func testLocalVariableAssignment() {
        analyze()
        assertUsed("param1", in: "myFunc(param1:param2:param3:param4:param5:)")
        assertUsed("param2", in: "myFunc(param1:param2:param3:param4:param5:)")
        assertUsed("param3", in: "myFunc(param1:param2:param3:param4:param5:)")
        assertUsed("param4", in: "myFunc(param1:param2:param3:param4:param5:)")
        assertUsed("param5", in: "myFunc(param1:param2:param3:param4:param5:)")
    }

    func testSimpleFunctionCall() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
    }

    func testFunctionCallWithNamedParameter() {
        analyze()
        assertUsed("param1", in: "myFunc(param1:param2:)")
        assertUnused("param2", in: "myFunc(param1:param2:)")
    }

    func testStringInterpolation() {
        analyze()
        assertUsed("param1", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed("param2", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed("param3", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed("param4", in: "myFunc(param1:param2:param3:param4:)")
    }

    func testInitializer() {
        analyze()
        assertUsed("param1", in: "init(param1:param2:)")
        assertUnused("param2", in: "init(param1:param2:)")
    }

    func testUsedInInitializerCall() {
        analyze()
        assertUsed("param1", in: "myFunc(param1:param2:)")
        assertUsed("param2", in: "myFunc(param1:param2:)")
    }

    func testReturn() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
    }

    func testIgnoreProtocolDeclaration() {
        analyze()
        XCTAssert(functions.isEmpty)
    }

    func testParamForGenericSpecialization() {
        analyze()
        assertUsed("param1", in: "myFunc(param1:param2:param3:)")
        assertUsed("param2", in: "myFunc(param1:param2:param3:)")
        assertUsed("param3", in: "myFunc(param1:param2:param3:)")
    }

    func testIgnoredParameter() {
        analyze()
        assertUsed("_", in: "myFunc(_:)")
    }

    func testShadowedByBlockParameter() {
        analyze()
        assertUnused("param1", in: "myFunc(param1:param2:param3:param4:)")
        assertUnused("param2", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed("param3", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed("param4", in: "myFunc(param1:param2:param3:param4:)")
    }

    func testBlockParameter() {
        analyze()
        assertUsed("block", in: "myFunc(block:)")
    }

    func testLocalVarDeclaredInBlock() {
        analyze()
        assertUnused("param", in: "myFunc(param:)")
    }

    func testSubscriptArgument() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
    }

    func testNestedFunction() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
    }

    func testNestedVariable() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
    }

    func testFatalErrorFunction() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
        assertUsed("param", in: "init(param:)")
    }

    func testUnavailableFunction() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
    }

    func testParameterPosition() {
        analyze()
        let function = functions.first!

        let param1 = function.parameters.first { $0.name == "param1" }!
        try XCTAssertEqual(XCTUnwrap(param1.location.line), 4)
        try XCTAssertEqual(XCTUnwrap(param1.location.column), 17)

        let param2 = function.parameters.first { $0.name == "param2" }!
        try XCTAssertEqual(XCTUnwrap(param2.location.line), 4)
        try XCTAssertEqual(XCTUnwrap(param2.location.column), 38)

        let param3 = function.parameters.first { $0.name == "param3" }!
        try XCTAssertEqual(XCTUnwrap(param3.location.line), 4)
        try XCTAssertEqual(XCTUnwrap(param3.location.column), 56)
    }

    func testInitializerPosition() {
        analyze()

        let init1 = functions[0]
        try XCTAssertEqual(XCTUnwrap(init1.location.line), 4)
        try XCTAssertEqual(XCTUnwrap(init1.location.column), 5)

        let init2 = functions[1]
        try XCTAssertEqual(XCTUnwrap(init2.location.line), 8)
        try XCTAssertEqual(XCTUnwrap(init2.location.column), 5)

        let init3 = functions[2]
        try XCTAssertEqual(XCTUnwrap(init3.location.line), 12)
        try XCTAssertEqual(XCTUnwrap(init3.location.column), 5)
    }

    func testMultiLineParameterPosition() {
        analyze()
        let function = functions.first!

        let param1 = function.parameters.first { $0.name == "param1" }!
        try XCTAssertEqual(XCTUnwrap(param1.location.line), 4)
        try XCTAssertEqual(XCTUnwrap(param1.location.column), 17)

        let param2 = function.parameters.first { $0.name == "param2" }!
        try XCTAssertEqual(XCTUnwrap(param2.location.line), 5)
        try XCTAssertEqual(XCTUnwrap(param2.location.column), 17)

        let param3 = function.parameters.first { $0.name == "param3" }!
        try XCTAssertEqual(XCTUnwrap(param3.location.line), 7)
        try XCTAssertEqual(XCTUnwrap(param3.location.column), 17)

        let param4 = function.parameters.first { $0.name == "param4" }!
        try XCTAssertEqual(XCTUnwrap(param4.location.line), 8)
        try XCTAssertEqual(XCTUnwrap(param4.location.column), 19)

        let param5 = function.parameters.first { $0.name == "param5" }!
        try XCTAssertEqual(XCTUnwrap(param5.location.line), 9)
        try XCTAssertEqual(XCTUnwrap(param5.location.column), 22)

        let param6 = function.parameters.first { $0.name == "param6" }!
        try XCTAssertEqual(XCTUnwrap(param6.location.line), 11)
        try XCTAssertEqual(XCTUnwrap(param6.location.column), 21)
    }

    func testIBActionAnnotatedFunction() {
        analyze()
        assertUsed("param", in: "myFunc(param:)")
    }

    func testBackticks() {
        analyze()
        assertUsed("class", in: "myFunc(class:func:otherUsed:otherUnused:)")
        assertUsed("otherUsed", in: "myFunc(class:func:otherUsed:otherUnused:)")

        assertUnused("func", in: "myFunc(class:func:otherUsed:otherUnused:)")
        assertUnused("otherUnused", in: "myFunc(class:func:otherUsed:otherUnused:)")
    }

    // MARK: - Private

    private var unusedParamsByFunction: [(Function, Set<Parameter>)] = []
    private var functions: [Function] = []

    private func analyze() {
        let sourceFile = SourceFile(path: testFixturePath, modules: ["UnusedParameterFixtures"])
        functions = try! UnusedParameterParser.parse(file: sourceFile, parseProtocols: false)
        let analyzer = UnusedParameterAnalyzer()

        for function in functions {
            let params = analyzer.analyze(function: function)
            unusedParamsByFunction.append((function, params))
        }
    }

    private func assertUnused(_ name: String, in functionName: String, file: StaticString = #file, line: UInt = #line) {
        let function = functions.first { $0.fullName == functionName }

        if let function {
            assert(function: function, hasParam: name, file: file, line: line)
            let unused = isUnused(param: name, in: function)
            XCTAssertTrue(unused, "Param '\(name)' is used in '\(functionName)'.", file: file, line: line)
        } else {
            XCTFail("No such function '\(functionName)'.", file: file, line: line)
        }
    }

    private func assertUsed(_ name: String, in functionName: String, file: StaticString = #file, line: UInt = #line) {
        let function = functions.first { $0.fullName == functionName }

        if let function {
            assert(function: function, hasParam: name, file: file, line: line)
            let unused = isUnused(param: name, in: function)
            XCTAssertFalse(unused, "Param '\(name)' is unused in '\(functionName)'.", file: file, line: line)
        } else {
            XCTFail("No such function '\(functionName)'.", file: file, line: line)
        }
    }

    private func isUnused(param name: String, in function: Function) -> Bool {
        for (innerFunction, params) in unusedParamsByFunction where innerFunction.fullName == function.fullName {
            return params.contains { $0.name == name }
        }

        return false
    }

    private func assert(function: Function, hasParam param: String, file: StaticString = #file, line: UInt = #line) {
        let hasParam = function.parameters.contains { $0.name == param }

        if !hasParam {
            XCTFail("Param '\(param)' does not exist in '\(function.name)'.", file: file, line: line)
        }
    }
}
