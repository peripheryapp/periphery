import Foundation
import XCTest
@testable import PeripheryKit

class XcodebuildLogParserTest: XCTestCase {
    private static var project: Project!
    private static var target: Target!

    private var project: Project! {
        return XcodebuildLogParserTest.project
    }

    private var target: Target! {
        return XcodebuildLogParserTest.target
    }

    override static func setUp() {
        super.setUp()

        project = try! Project.make(path: PeripheryProjectPath)
        target = project.targets.first { $0.name == "PeripheryKit" }!
    }

    func testSanitizedModuleName() {
        let parser = XcodebuildLogParser(log: "")

        let pairs = [
            "My !@#$%^&*()-_=+\\/?,.<>'`~{}[]Target": "My_____________________________Target",
            "123MyTarget": "_23MyTarget", // No leading numbers
            "🤘🏼MyTarget": "__MyTarget" // No emoji
        ]

        for (value, expected) in pairs {
            XCTAssertEqual(parser.sanitize(moduleName: value), expected)
        }
    }

    func testParseSwiftcInvocation() throws {
        let xcodebuild = Xcodebuild.make()
        try xcodebuild.clearDerivedData(for: project)
        let log = try xcodebuild.build(project: project, scheme: "RetentionFixtures")
        let parser = XcodebuildLogParser(log: log)
        let target = project.targets.first { $0.name == "RetentionFixtures" }!
        let arguments = try! parser.getSwiftcInvocation(target: target.name, module: target.moduleName).arguments
        // We can't check all arguments so just check for a few
        let moduleName = arguments.first { $0.key == "-module-name" }
        XCTAssertNotNil(moduleName)
        XCTAssertEqual(moduleName!.value, "RetentionFixtures")

        let targetArgument = arguments.first { $0.key == "-target" }
        XCTAssertNotNil(target)
        XCTAssertEqual(targetArgument!.value, "x86_64-apple-macos10.12")

        // Check that files have been removed
        let containsFile = arguments.contains(where: { $0.key.hasSuffix(".swift") })
        XCTAssertFalse(containsFile)
    }

    func testParseFilenameWithSpaces() {
        let log = """
CompileSwiftSources normal x86_64 com.apple.xcode.tools.swift.compiler
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PeripheryKit -j8 /path/File\\ With\\ Spaces.swift
"""

        let parser = XcodebuildLogParser(log: log)
        let files = try! parser.getSwiftcInvocation(target: target.name, module: target.moduleName).files

        XCTAssertEqual(files, ["/path/File With Spaces.swift"])
    }

    func testParseFilenameWithSingleQuote() {
        let log = """
CompileSwiftSources normal x86_64 com.apple.xcode.tools.swift.compiler
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PeripheryKit -j8 /path/What\\'s This.swift
"""

        let parser = XcodebuildLogParser(log: log)
        let files = try! parser.getSwiftcInvocation(target: target.name, module: target.moduleName).files

        XCTAssertEqual(files, ["/path/What's This.swift"])
    }

    func testParseFilenameWithDoubleQuote() {
        let log = """
CompileSwiftSources normal x86_64 com.apple.xcode.tools.swift.compiler
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PeripheryKit -j8 /path/Oh\\ \"My\"\\ God.swift
"""

        let parser = XcodebuildLogParser(log: log)
        let files = try! parser.getSwiftcInvocation(target: target.name, module: target.moduleName).files

        XCTAssertEqual(files, ["/path/Oh \"My\" God.swift"])
    }

    func testParseSwifcPathWithHyphen() {
        let log = """
CompileSwiftSources normal x86_64 com.apple.xcode.tools.swift.compiler
    /Applications/Xcode-9.3.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PeripheryKit -j8 /path/file.swift
"""

        let parser = XcodebuildLogParser(log: log)
        let arguments = try! parser.getSwiftcInvocation(target: target.name, module: target.moduleName).arguments

        XCTAssertEqual(arguments.first!.key, "-module-name")
    }

    func testParseSwifcPathWithSpace() {
        let log = """
CompileSwiftSources normal x86_64 com.apple.xcode.tools.swift.compiler
    /Applications/Xcode\\ Beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PeripheryKit -j8 /path/file.swift
"""

        let parser = XcodebuildLogParser(log: log)
        let arguments = try! parser.getSwiftcInvocation(target: target.name, module: target.moduleName).arguments

        XCTAssertEqual(arguments.first!.key, "-module-name")
    }

    func testParseTargetContainingNonLatin1Characters() {
        // Xcode outputs target & project names in macOSRoman encoding.
        let log = """
CompileSwiftSources normal x86_64 com.apple.xcode.tools.swift.compiler
    /Applications/Xcode\\ Beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name ØcmeApp -j8 /path/file.swift
"""

        let parser = XcodebuildLogParser(log: log)
        XCTAssertNoThrow(try parser.getSwiftcInvocation(target: "ØcmeApp", module: "ØcmeApp"))
    }
}
