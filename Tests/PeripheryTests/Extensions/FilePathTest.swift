import Foundation
import XCTest
import SystemPackage
import PathKit

class FilePathTest: XCTestCase {
    func testRelativeTo() {
        XCTAssertEqual(FilePath("/a/b/c").relativeTo(FilePath("/a/b/c")).string, ".")
        XCTAssertEqual(FilePath("/a/b/c/d").relativeTo(FilePath("/a/b")).string, "c/d")
        XCTAssertEqual(FilePath("/a/b/c/d").relativeTo(FilePath("/a/b/c")).string, "d")
        XCTAssertEqual(FilePath("/a/b").relativeTo(FilePath("/a/b/c/d")).string, "../..")
    }
}
