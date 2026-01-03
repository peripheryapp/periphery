import Foundation
@testable import Indexer
import SystemPackage
import XCTest

final class XCStringsParserTest: XCTestCase {
    func testParsesStringKeys() throws {
        let xcstringsContent = """
        {
          "sourceLanguage": "en",
          "version": "1.0",
          "strings": {
            "hello_world": {
              "localizations": {
                "en": { "stringUnit": { "state": "translated", "value": "Hello, World!" } }
              }
            },
            "goodbye": {
              "localizations": {
                "en": { "stringUnit": { "state": "translated", "value": "Goodbye!" } }
              }
            },
            "welcome_message": {}
          }
        }
        """

        let keys = try parseXCStrings(xcstringsContent)
        XCTAssertEqual(keys, ["hello_world", "goodbye", "welcome_message"])
    }

    func testParsesEmptyStrings() throws {
        let xcstringsContent = """
        {
          "sourceLanguage": "en",
          "version": "1.0",
          "strings": {}
        }
        """

        let keys = try parseXCStrings(xcstringsContent)
        XCTAssertEqual(keys, [])
    }

    func testParsesWithoutVersion() throws {
        let xcstringsContent = """
        {
          "sourceLanguage": "en",
          "strings": {
            "only_key": {}
          }
        }
        """

        let keys = try parseXCStrings(xcstringsContent)
        XCTAssertEqual(keys, ["only_key"])
    }

    // MARK: - Private

    private func parseXCStrings(_ content: String) throws -> Set<String> {
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile = tmpDir.appendingPathComponent("TestStrings.xcstrings")
        try content.write(to: tmpFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tmpFile)
        }

        let path = FilePath(tmpFile.path)
        return try XCStringsParser(path: path).parse()
    }
}
