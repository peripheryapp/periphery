import Foundation
import XCTest
import SystemPackage

class FilePathTest: XCTestCase {
    func testMakeAbsolute() {
        let current = FilePath("/current")
        XCTAssertEqual(FilePath.makeAbsolute("/a", relativeTo: current).string, "/a")
        XCTAssertEqual(FilePath.makeAbsolute("a", relativeTo: current).string, "/current/a")
        XCTAssertEqual(FilePath.makeAbsolute("./a", relativeTo: current).string, "/current/a")
    }

    func testRelativeTo() {
        XCTAssertEqual(FilePath("/a/b/c").relativeTo(FilePath("/a/b/c")).string, ".")
        XCTAssertEqual(FilePath("/a/b/c/d").relativeTo(FilePath("/a/b")).string, "c/d")
        XCTAssertEqual(FilePath("/a/b/c/d").relativeTo(FilePath("/a/b/c")).string, "d")
        XCTAssertEqual(FilePath("/a/b").relativeTo(FilePath("/a/b/c/d")).string, "../..")
    }
}
