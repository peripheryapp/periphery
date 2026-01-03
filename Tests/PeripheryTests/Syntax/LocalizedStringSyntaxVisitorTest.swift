import Foundation
import Logger
import Shared
@testable import SourceGraph
@testable import SyntaxAnalysis
import SystemPackage
@testable import TestShared
import XCTest

final class LocalizedStringSyntaxVisitorTest: XCTestCase {
    func testDetectsNSLocalizedString() throws {
        let usedKeys = try collectUsedStringKeys(from: """
        let greeting = NSLocalizedString("hello_world", comment: "")
        let farewell = NSLocalizedString("goodbye", tableName: "Other", comment: "")
        """)

        XCTAssertEqual(usedKeys, ["hello_world", "goodbye"])
    }

    func testDetectsStringLocalized() throws {
        let usedKeys = try collectUsedStringKeys(from: """
        let greeting = String(localized: "welcome_message")
        let farewell = String(localized: "farewell_message", table: "Main")
        """)

        XCTAssertEqual(usedKeys, ["welcome_message", "farewell_message"])
    }

    func testDetectsLocalizedStringKey() throws {
        let usedKeys = try collectUsedStringKeys(from: """
        let key = LocalizedStringKey("settings_title")
        """)

        XCTAssertEqual(usedKeys, ["settings_title"])
    }

    func testDetectsLocalizedStringResource() throws {
        let usedKeys = try collectUsedStringKeys(from: """
        let resource = LocalizedStringResource("resource_key")
        """)

        XCTAssertEqual(usedKeys, ["resource_key"])
    }

    func testDetectsSwiftUIText() throws {
        let usedKeys = try collectUsedStringKeys(from: """
        Text("button_label")
        """)

        XCTAssertEqual(usedKeys, ["button_label"])
    }

    func testDetectsBundleLocalizedString() throws {
        let usedKeys = try collectUsedStringKeys(from: """
        Bundle.main.localizedString(forKey: "bundle_key", value: nil, table: nil)
        """)

        XCTAssertEqual(usedKeys, ["bundle_key"])
    }

    func testIgnoresStringInterpolations() throws {
        let usedKeys = try collectUsedStringKeys(from: """
        let name = "World"
        let greeting = NSLocalizedString("hello \\(name)", comment: "")
        """)

        XCTAssertEqual(usedKeys, [])
    }

    func testMultipleKeys() throws {
        let usedKeys = try collectUsedStringKeys(from: """
        NSLocalizedString("key1", comment: "")
        String(localized: "key2")
        Text("key3")
        LocalizedStringKey("key4")
        """)

        XCTAssertEqual(usedKeys, ["key1", "key2", "key3", "key4"])
    }

    // MARK: - Private

    private func collectUsedStringKeys(from source: String) throws -> Set<String> {
        // Create a temporary file with the source
        let tmpDir = FileManager.default.temporaryDirectory
        let tmpFile = tmpDir.appendingPathComponent("LocalizedStringTest.swift")
        try source.write(to: tmpFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: tmpFile)
        }

        let path = FilePath(tmpFile.path)
        let sourceFile = SourceFile(path: path, modules: ["Test"])

        let shell = Shell(logger: Logger(quiet: true))
        let swiftVersion = SwiftVersion(shell: shell)
        let multiplexingVisitor = try MultiplexingSyntaxVisitor(file: sourceFile, swiftVersion: swiftVersion)
        let visitor = multiplexingVisitor.add(LocalizedStringSyntaxVisitor.self)
        multiplexingVisitor.visit()

        return visitor.usedStringKeys
    }
}
