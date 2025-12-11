import Foundation
@testable import SourceGraph
@testable import SyntaxAnalysis
@testable import TestShared
import XCTest

final class UnusedParameterTest: XCTestCase {
    func testSimpleUnused() {
        analyze()
        assertUnused(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testShadowed() {
        analyze()
        assertUnused(label: "param", name: "param", in: "myFunc1(param:)")
        assertUnused(label: "param", name: "param", in: "myFunc2(param:)")
        assertUnused(label: "param", name: "param", in: "myFunc3(param:)")
    }

    func testShadowedAfterUse() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testLocalVariableAssignment() {
        analyze()
        assertUsed(label: "param1", name: "param1", in: "myFunc(param1:param2:param3:param4:param5:)")
        assertUsed(label: "param2", name: "param2", in: "myFunc(param1:param2:param3:param4:param5:)")
        assertUsed(label: "param3", name: "param3", in: "myFunc(param1:param2:param3:param4:param5:)")
        assertUsed(label: "param4", name: "param4", in: "myFunc(param1:param2:param3:param4:param5:)")
        assertUsed(label: "param5", name: "param5", in: "myFunc(param1:param2:param3:param4:param5:)")
    }

    func testSimpleFunctionCall() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testFunctionCallWithNamedParameter() {
        analyze()
        assertUsed(label: "param1", name: "param1", in: "myFunc(param1:param2:)")
        assertUnused(label: "param2", name: "param2", in: "myFunc(param1:param2:)")
    }

    func testStringInterpolation() {
        analyze()
        assertUsed(label: "param1", name: "param1", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed(label: "param2", name: "param2", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed(label: "param3", name: "param3", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed(label: "param4", name: "param4", in: "myFunc(param1:param2:param3:param4:)")
    }

    func testInitializer() {
        analyze()
        assertUsed(label: "param1", name: "param1", in: "init(param1:param2:)")
        assertUnused(label: "param2", name: "param2", in: "init(param1:param2:)")
    }

    func testUsedInInitializerCall() {
        analyze()
        assertUsed(label: "param1", name: "param1", in: "myFunc(param1:param2:)")
        assertUsed(label: "param2", name: "param2", in: "myFunc(param1:param2:)")
    }

    func testReturn() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testIgnoreProtocolDeclaration() {
        analyze()
        XCTAssert(functions.isEmpty)
    }

    func testParamForGenericSpecialization() {
        analyze()
        assertUsed(label: "param1", name: "param1", in: "myFunc(param1:param2:param3:)")
        assertUsed(label: "param2", name: "param2", in: "myFunc(param1:param2:param3:)")
        assertUsed(label: "param3", name: "param3", in: "myFunc(param1:param2:param3:)")
    }

    func testIgnoredParameter() {
        analyze()
        assertUsed(label: "_", name: "_", in: "myFunc(_:)")
        assertUsed(label: "label", name: "_", in: "myFunc2(label:)")
        assertUnused(label: "_", name: "name", in: "myFunc3(_:)")
    }

    func testShadowedByBlockParameter() {
        analyze()
        assertUnused(label: "param1", name: "param1", in: "myFunc(param1:param2:param3:param4:)")
        assertUnused(label: "param2", name: "param2", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed(label: "param3", name: "param3", in: "myFunc(param1:param2:param3:param4:)")
        assertUsed(label: "param4", name: "param4", in: "myFunc(param1:param2:param3:param4:)")
    }

    func testBlockParameter() {
        analyze()
        assertUsed(label: "block", name: "block", in: "myFunc(block:)")
    }

    func testLocalVarDeclaredInBlock() {
        analyze()
        assertUnused(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testSubscriptArgument() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testNestedFunction() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testNestedVariable() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testFatalErrorFunction() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
        assertUsed(label: "param", name: "param", in: "init(param:)")
    }

    func testUnavailableFunction() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testParameterPosition() {
        analyze()
        let function = functions.first!

        let param1 = function.parameters.first { $0.label.text == "param1" }!
        try XCTAssertEqual(XCTUnwrap(param1.location.line), 4)
        try XCTAssertEqual(XCTUnwrap(param1.location.column), 17)

        let param2 = function.parameters.first { $0.name.text == "param2" }!
        try XCTAssertEqual(XCTUnwrap(param2.location.line), 4)
        try XCTAssertEqual(XCTUnwrap(param2.location.column), 38)

        let param3 = function.parameters.first { $0.name.text == "param3" }!
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

        let param1 = function.parameters.first { $0.label.text == "param1" }!
        try XCTAssertEqual(XCTUnwrap(param1.location.line), 4)
        try XCTAssertEqual(XCTUnwrap(param1.location.column), 17)

        let param2 = function.parameters.first { $0.label.text == "param2" }!
        try XCTAssertEqual(XCTUnwrap(param2.location.line), 5)
        try XCTAssertEqual(XCTUnwrap(param2.location.column), 17)

        let param3 = function.parameters.first { $0.label.text == "param3" }!
        try XCTAssertEqual(XCTUnwrap(param3.location.line), 7)
        try XCTAssertEqual(XCTUnwrap(param3.location.column), 17)

        let param4 = function.parameters.first { $0.name.text == "param4" }!
        try XCTAssertEqual(XCTUnwrap(param4.location.line), 8)
        try XCTAssertEqual(XCTUnwrap(param4.location.column), 19)

        let param5 = function.parameters.first { $0.name.text == "param5" }!
        try XCTAssertEqual(XCTUnwrap(param5.location.line), 9)
        try XCTAssertEqual(XCTUnwrap(param5.location.column), 22)

        let param6 = function.parameters.first { $0.name.text == "param6" }!
        try XCTAssertEqual(XCTUnwrap(param6.location.line), 11)
        try XCTAssertEqual(XCTUnwrap(param6.location.column), 21)
    }

    func testIBActionAnnotatedFunction() {
        analyze()
        assertUsed(label: "param", name: "param", in: "myFunc(param:)")
    }

    func testBackticks() {
        analyze()
        assertUsed(label: "class", name: "class", in: "myFunc(class:func:otherUsed:otherUnused:)")
        assertUsed(label: "otherUsed", name: "otherUsed", in: "myFunc(class:func:otherUsed:otherUnused:)")

        assertUnused(label: "func", name: "func", in: "myFunc(class:func:otherUsed:otherUnused:)")
        assertUnused(label: "otherUnused", name: "otherUnused", in: "myFunc(class:func:otherUsed:otherUnused:)")
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

    private func assertUnused(label: String, name: String, in functionName: String, file: StaticString = #file, line: UInt = #line) {
        let function = functions.first { $0.fullName == functionName }

        if let function {
            assertParam(label: label, name: name, in: function, file: file, line: line)
            let unused = isUnused(param: name, in: function)
            XCTAssertTrue(unused, "Param '\(name)' is used in '\(functionName)'.", file: file, line: line)
        } else {
            XCTFail("No such function '\(functionName)'.", file: file, line: line)
        }
    }

    private func assertUsed(label: String, name: String, in functionName: String, file: StaticString = #file, line: UInt = #line) {
        let function = functions.first { $0.fullName == functionName }

        if let function {
            assertParam(label: label, name: name, in: function, file: file, line: line)
            let unused = isUnused(param: name, in: function)
            XCTAssertFalse(unused, "Param '\(name)' is unused in '\(functionName)'.", file: file, line: line)
        } else {
            XCTFail("No such function '\(functionName)'.", file: file, line: line)
        }
    }

    private func isUnused(param name: String, in function: Function) -> Bool {
        for (innerFunction, params) in unusedParamsByFunction where innerFunction.fullName == function.fullName {
            return params.contains { $0.name.text == name }
        }

        return false
    }

    private func assertParam(label: String, name: String, in function: Function, file: StaticString = #file, line: UInt = #line) {
        let hasParam = function.parameters.contains { $0.label.text == label && $0.name.text == name }

        if !hasParam {
            XCTFail("Param (\(label), \(name)) does not exist in '\(function.name)'.", file: file, line: line)
        }
    }
}
