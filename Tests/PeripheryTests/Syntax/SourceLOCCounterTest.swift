import SwiftParser
import SwiftSyntax
@testable import SyntaxAnalysis
import XCTest

final class SourceLOCCounterTest: XCTestCase {
    func testExcludesBlankAndCommentOnlyLines() {
        let source = #"""
        // Header comment

        import Foundation

        /* Block comment
           still comment */

        struct Foo {
            let value = 1 // trailing comment
        }
        """#

        XCTAssertEqual(countLOC(in: source), 4)
    }

    func testCountsLinesTouchedByMultilineStringLiteralTokens() {
        let source = #"""
        let text = """
        hello
        world
        """
        """#

        XCTAssertEqual(countLOC(in: source), 4)
    }

    func testExcludesStandaloneDocCommentsButIncludesCodeWithInlineComments() {
        let source = #"""
        /// Documentation
        let value = 1

        let other = value /* inline block comment */
        // trailing standalone comment
        """#

        XCTAssertEqual(countLOC(in: source), 2)
    }

    func testCommentOnlyFileHasZeroLOC() {
        let source = #"""
        // one
        /* two */

        /// three
        """#

        XCTAssertEqual(countLOC(in: source), 0)
    }

    func testCountsMixedTopLevelAndNestedDeclarationsWithNestedComments() {
        let source = #"""
        struct Outer {
            // comment before property
            let value = 1

            final class Inner {
                /*
                 Nested block comment
                 still comment
                 */
                func greet() {
                    let text = "hello"
                    // trailing nested comment
                }
            }
        }

        enum Status {
            case ready
        }
        """#

        XCTAssertEqual(countLOC(in: source), 11)
    }

    private func countLOC(in source: String) -> Int {
        let syntax = Parser.parse(source: source)
        let locationConverter = SourceLocationConverter(fileName: "Test.swift", tree: syntax)
        return SourceLOCCounter.countLines(of: syntax, using: locationConverter)
    }
}
