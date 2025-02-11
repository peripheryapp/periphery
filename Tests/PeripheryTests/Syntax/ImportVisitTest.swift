import Foundation
@testable import SourceGraph
@testable import SyntaxAnalysis
@testable import TestShared
import XCTest

final class ImportVisitTest: XCTestCase {
    private var results: [ImportStatement]!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let multiplexingVisitor = try MultiplexingSyntaxVisitor(file: fixturePath)
        let visitor = multiplexingVisitor.add(ImportSyntaxVisitor.self)
        multiplexingVisitor.visit()
        results = visitor.importStatements
    }

    override func tearDown() {
        results = nil
        super.tearDown()
    }

    func testCommentCommands() {
        let expectedIgnored = ["CoreFoundation", "Swift"]
        let actualIgnored = results.filter { $0.commentCommands.contains(.ignore) }.map(\.module)
        XCTAssertEqual(actualIgnored, expectedIgnored, "Ignored modules did not match the expected set")

        let actualUnignored = results.filter { !$0.commentCommands.contains(.ignore) }.map(\.module)
        let expectedUnignored = ["Foundation"]
        XCTAssertEqual(actualUnignored, expectedUnignored, "Unignored modules did not match the expected set")
    }

    // MARK: - Private

    private var fixturePath: SourceFile {
        let path = FixturesProjectPath.appending("Sources/DeclarationVisitorFixtures/ImportFixture.swift")
        return SourceFile(path: path, modules: ["DeclarationVisitorFixtures"])
    }
}
