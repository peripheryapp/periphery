import Foundation
@testable import SourceGraph
import SwiftSyntax
@testable import SyntaxAnalysis
import XCTest

final class CommentCommandTest: XCTestCase {
    func testParseIgnore() {
        assertParsesCommand("// periphery:ignore", expected: .ignore)
        assertParsesCommand("/// periphery:ignore", expected: .ignore)
        assertParsesCommand("/* periphery:ignore */", expected: .ignore)
        assertParsesCommand("/** periphery:ignore */", expected: .ignore)
    }

    func testParseIgnoreAll() {
        assertParsesCommand("// periphery:ignore:all", expected: .ignoreAll)
    }

    func testParseIgnoreParameters() {
        assertParsesCommand("// periphery:ignore:parameters foo", expected: .ignoreParameters(["foo"]))
        assertParsesCommand("// periphery:ignore:parameters foo,bar", expected: .ignoreParameters(["foo", "bar"]))
    }

    func testAllowsLeadingWhitespace() {
        assertParsesCommand("//   periphery:ignore", expected: .ignore)
        assertParsesCommand("///  periphery:ignore", expected: .ignore)
        assertParsesCommand("/*   periphery:ignore */", expected: .ignore)
    }

    func testIgnoresCommandsWithPrecedingText() {
        assertDoesNotParseCommand("// some text periphery:ignore")
        assertDoesNotParseCommand("/// Docs about periphery:ignore")
        assertDoesNotParseCommand("// `periphery:ignore` is used to ignore")
        assertDoesNotParseCommand("/* text periphery:ignore */")
    }

    func testTrailingCommentAfterHyphen() {
        // Anything after '-' is treated as a trailing comment and ignored
        assertParsesCommand("// periphery:ignore - this is a reason for ignoring", expected: .ignore)
        assertParsesCommand("// periphery:ignore:all - ignore entire file", expected: .ignoreAll)
        assertParsesCommand("// periphery:ignore:parameters foo - param is unused intentionally", expected: .ignoreParameters(["foo"]))
    }

    // MARK: - Helpers

    private func assertParsesCommand(_ comment: String, expected: CommentCommand, file: StaticString = #file, line: UInt = #line) {
        let trivia = parseTrivia(comment)
        let commands = CommentCommand.parseCommands(in: trivia)
        XCTAssertEqual(commands.count, 1, "Expected exactly one command from '\(comment)'", file: file, line: line)
        if let command = commands.first {
            XCTAssertEqual(command, expected, "Command mismatch for '\(comment)'", file: file, line: line)
        }
    }

    private func assertDoesNotParseCommand(_ comment: String, file: StaticString = #file, line: UInt = #line) {
        let trivia = parseTrivia(comment)
        let commands = CommentCommand.parseCommands(in: trivia)
        XCTAssertTrue(commands.isEmpty, "Expected no commands from '\(comment)', but got: \(commands)", file: file, line: line)
    }

    private func parseTrivia(_ comment: String) -> Trivia {
        // Determine the trivia piece type based on comment prefix
        let piece: TriviaPiece = if comment.hasPrefix("///") {
            .docLineComment(comment)
        } else if comment.hasPrefix("//") {
            .lineComment(comment)
        } else if comment.hasPrefix("/**") {
            .docBlockComment(comment)
        } else if comment.hasPrefix("/*") {
            .blockComment(comment)
        } else {
            .lineComment(comment)
        }
        return Trivia(pieces: [piece])
    }
}
