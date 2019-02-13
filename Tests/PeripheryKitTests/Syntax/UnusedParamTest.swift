import Foundation
import XCTest
import PathKit

@testable import PeripheryKit

class UnusedParamTest: XCTestCase {
    func testSimpleUnused() {
        analyze()
        XCTAssertUnused("param", of: "myFunc(param:)")
    }

    func testShadowed() {
        analyze()
        XCTAssertUnused("param", of: "myFunc1(param:)")
        XCTAssertUnused("param", of: "myFunc2(param:)")
        XCTAssertUnused("param", of: "myFunc3(param:)")
    }

    func testShadowedAfterUse() {
        analyze()
        XCTAssertUsed("param", of: "myFunc(param:)")
    }

    func testLocalVariableAssignment() {
        analyze()
        XCTAssertUsed("param1", of: "myFunc(param1:param2:)")
        XCTAssertUsed("param2", of: "myFunc(param1:param2:)")
    }

    func testSimpleFunctionCall() {
        analyze()
        XCTAssertUsed("param", of: "myFunc(param:)")
    }

    func testFunctionCallWithNamedParameter() {
        analyze()
        XCTAssertUsed("param1", of: "myFunc(param1:param2:)")
        XCTAssertUnused("param2", of: "myFunc(param1:param2:)")
    }

    func testStringInterpolation() {
        analyze()
        XCTAssertUsed("param1", of: "myFunc(param1:param2:param3:param4:)")
        XCTAssertUsed("param2", of: "myFunc(param1:param2:param3:param4:)")
        XCTAssertUsed("param3", of: "myFunc(param1:param2:param3:param4:)")
        XCTAssertUsed("param4", of: "myFunc(param1:param2:param3:param4:)")
    }

    func testInitializer() {
        analyze()
        XCTAssertUsed("param1", of: "init(param1:param2:)")
        XCTAssertUnused("param2", of: "init(param1:param2:)")
    }

    func testUsedInInitializerCall() {
        analyze()
        XCTAssertUsed("param1", of: "myFunc(param1:param2:)")
        XCTAssertUsed("param2", of: "myFunc(param1:param2:)")
    }

    func testReturn() {
        analyze()
        XCTAssertUsed("param", of: "myFunc(param:)")
    }

    func testIgnoreProtocolDeclaration() {
        analyze()
        XCTAssert(functions.count == 0)
    }

    func testParamForGenericSpecialization() {
        analyze()
        XCTAssertUsed("param1", of: "myFunc(param1:param2:param3:)")
        XCTAssertUsed("param2", of: "myFunc(param1:param2:param3:)")
        XCTAssertUsed("param3", of: "myFunc(param1:param2:param3:)")
    }

    func testIgnoredParameter() {
        analyze()
        XCTAssertUsed("_", of: "myFunc(_:)")
    }

    func testShadowedByBlockParameter() {
        analyze()
        XCTAssertUnused("param1", of: "myFunc(param1:param2:param3:param4:)")
        XCTAssertUnused("param2", of: "myFunc(param1:param2:param3:param4:)")
        XCTAssertUsed("param3", of: "myFunc(param1:param2:param3:param4:)")
        XCTAssertUsed("param4", of: "myFunc(param1:param2:param3:param4:)")
    }

    func testBlockParameter() {
        analyze()
        XCTAssertUsed("block", of: "myFunc(block:)")
    }

    func testLocalVarDeclaredInBlock() {
        analyze()
        XCTAssertUnused("param", of: "myFunc(param:)")
    }

    func testSubscriptArgument() {
        analyze()
        XCTAssertUsed("param", of: "myFunc(param:)")
    }

    func testNestedFunction() {
        analyze()
        XCTAssertUsed("param", of: "myFunc(param:)")
    }

    func testFatalErrorFunction() {
        analyze()
        XCTAssertUsed("param", of: "myFunc(param:)")
        XCTAssertUsed("decoder", of: "init(coder decoder:)")
    }

    func testInitializerPosition() {
        analyze()

        let init1 = functions.first!
        XCTAssertEqual(init1.location.line!, 4)
        XCTAssertEqual(init1.location.column!, 5)
        XCTAssertEqual(init1.location.offset!, 47)

        let init2 = functions.last!
        XCTAssertEqual(init2.location.line!, 8)
        XCTAssertEqual(init2.location.column!, 5)
        XCTAssertEqual(init2.location.offset!, 110)
    }

    // MARK: - Known Failures

    func knownfailure_testMultiLineParameterPosition() {
        // https://bugs.swift.org/browse/SR-9306
        analyze()
        let function = functions.first!
        let param1 = function.parameters.first { $0.name == "param1" }!
        let param2 = function.parameters.first { $0.name == "param2" }!
        XCTAssertEqual(param1.location.line!, 4)
        XCTAssertEqual(param2.location.line!, 5)
    }

    // MARK: - Private

    private var unusedParamsByFunction: [(Function, Set<Parameter>)] = []
    private var functions: [Function] = []

    private func analyze() {
        let parser = UnusedParamParser(file: fixturePath, parseProtocols: false)
        functions = try! parser.parse()
        let analyzer = UnusedParameterAnalyzer()

        for function in functions {
            let params = analyzer.analyze(function: function)
            unusedParamsByFunction.append((function, params))
        }
    }

    private var fixturePath: Path {
        var testName = String(name.split(separator: " ").last!)
        testName = testName.replacingOccurrences(of: "]", with: "")
        return ProjectRootPath + "Tests/SyntaxFixtures/\(testName).swift"
    }

    private func XCTAssertUnused(_ name: String, of functionName: String, file: StaticString = #file, line: UInt = #line) {
        let function = functions.first { $0.fullName == functionName }

        if let function = function {
            assert(function: function, hasParam: name, file: file, line: line)
            let unused = isUnused(param: name, in: function)
            XCTAssertTrue(unused, "Param '\(name)' is used in '\(functionName)'.", file: file, line: line)
        } else {
            XCTFail("No such function '\(functionName)'.", file: file, line: line)
        }
    }

    private func XCTAssertUsed(_ name: String, of functionName: String, file: StaticString = #file, line: UInt = #line) {
        let function = functions.first { $0.fullName == functionName }

        if let function = function {
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
