import SystemPackage
import XCTest

public extension XCTestCase {
    var testFixturePath: FilePath {
        #if os(macOS)
        let testName = String(name.split(separator: " ").last!).replacingOccurrences(of: "]", with: "")
        #else
        let testName = String(name.split(separator: ".", maxSplits: 1).last!)
        #endif

        let suiteName = String(describing: Self.self).dropLast(4)
         return ProjectRootPath.appending("Tests/Fixtures/\(suiteName)Fixtures/\(testName).swift")
    }
}
