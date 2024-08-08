import Shared
import SystemPackage
import XCTest

final class FilePathGlobTest: XCTestCase {
    private let files = ["foo", "bar", "baz", "dir1/file1.ext", "dir1/dir2/dir3/file2.ext"]
    private let baseDir = FilePath.current.appending("tmp/FilePathGlobTest").string
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        super.setUp()
        try fileManager.createDirectory(atPath: "\(baseDir)/dir1/dir2/dir3/", withIntermediateDirectories: true, attributes: nil)
        files.forEach { fileManager.createFile(atPath: "\(baseDir)/\($0)", contents: nil, attributes: nil) }
    }

    override func tearDownWithError() throws {
        super.tearDown()
        try fileManager.removeItem(atPath: baseDir)
    }

    func testBraces() {
        let pattern = "\(baseDir)/ba{r,y,z}"
        let paths = FilePath.glob(pattern).sorted()
        XCTAssertPathsEqual(paths, ["\(baseDir)/bar", "\(baseDir)/baz"])
    }

    func testNothingMatches() {
        let pattern = "\(baseDir)/nothing"
        let paths = FilePath.glob(pattern).sorted()
        XCTAssertPathsEqual(paths, [])
    }

    func testDirectAccess() {
        let pattern = "\(baseDir)/ba{r,y,z}"
        let paths = FilePath.glob(pattern).sorted()
        XCTAssertPathsEqual(paths, ["\(baseDir)/bar", "\(baseDir)/baz"])
    }

    func testGlobstarNoSlash() {
        // Should be the equivalent of "ls -d -1 /(baseDir)/**"
        let pattern = "\(baseDir)/**"
        let paths = FilePath.glob(pattern).sorted()
        XCTAssertPathsEqual(paths, [
            baseDir,
            "\(baseDir)/bar",
            "\(baseDir)/baz",
            "\(baseDir)/dir1",
            "\(baseDir)/dir1/dir2",
            "\(baseDir)/dir1/dir2/dir3",
            "\(baseDir)/dir1/dir2/dir3/file2.ext",
            "\(baseDir)/dir1/file1.ext",
            "\(baseDir)/foo"
        ])
    }

    func testGlobstarWithSlash() {
        // Should be the equivalent of "ls -d -1 /(baseDir)/**/"
        let pattern = "\(baseDir)/**/"
        let paths = FilePath.glob(pattern).sorted()
        XCTAssertPathsEqual(paths, [
            baseDir,
            "\(baseDir)/dir1",
            "\(baseDir)/dir1/dir2",
            "\(baseDir)/dir1/dir2/dir3"
        ])
    }

    func testGlobstarWithSlashAndWildcard() {
        // Should be the equivalent of "ls -d -1 /(baseDir)/**/*"
        let pattern = "\(baseDir)/**/*"
        let paths = FilePath.glob(pattern).sorted()
        XCTAssertPathsEqual(paths, [
            "\(baseDir)/bar",
            "\(baseDir)/baz",
            "\(baseDir)/dir1",
            "\(baseDir)/dir1/dir2",
            "\(baseDir)/dir1/dir2/dir3",
            "\(baseDir)/dir1/dir2/dir3/file2.ext",
            "\(baseDir)/dir1/file1.ext",
            "\(baseDir)/foo"
        ])
    }

    func testDoubleGlobstar() {
        let pattern = "\(baseDir)/**/dir2/**/*"
        let paths = FilePath.glob(pattern).sorted()
        XCTAssertPathsEqual(paths, [
            "\(baseDir)/dir1/dir2/dir3",
            "\(baseDir)/dir1/dir2/dir3/file2.ext"
        ])
    }

    func testRelative() {
        FilePath(baseDir).chdir {
            let pattern = "**/*.ext"
            let paths = FilePath.glob(pattern).sorted()
            XCTAssertPathsEqual(paths, [
                "\(baseDir)/dir1/dir2/dir3/file2.ext",
                "\(baseDir)/dir1/file1.ext"
            ])
        }
    }

    func testRelativeParent() {
        FilePath("\(baseDir)/dir1").chdir {
            let pattern = "../bar"
            let paths = FilePath.glob(pattern).sorted()
            XCTAssertPathsEqual(paths, [
                "\(baseDir)/bar"
            ])
        }

        FilePath("\(baseDir)/dir1/dir2").chdir {
            let pattern = "../../**/*.ext"
            let paths = FilePath.glob(pattern).sorted()
            XCTAssertPathsEqual(paths, [
                "\(baseDir)/dir1/dir2/dir3/file2.ext",
                "\(baseDir)/dir1/file1.ext"
            ])
        }
    }

    // MARK: - Private

    private func XCTAssertPathsEqual(_ filePaths: [FilePath], _ stringPaths: [String], file: StaticString = #file, line: UInt = #line) {
        let convertedFilePaths = filePaths.map { $0.string }
        XCTAssertEqual(convertedFilePaths, stringPaths, file: file, line: line)
    }
}
