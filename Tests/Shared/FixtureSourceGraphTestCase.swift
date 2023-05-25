import SystemPackage
@testable import PeripheryKit
import XCTest

class FixtureSourceGraphTestCase: SourceGraphTestCase {
    class override func setUp() {
        super.setUp()
        _sourceFiles = nil
    }

    func analyze(retainPublic: Bool = false,
                 retainObjcAccessible: Bool = false,
                 retainObjcAnnotated: Bool = false,
                 testBlock: () throws -> Void
    ) rethrows {
        configuration.retainPublic = retainPublic
        configuration.retainObjcAccessible = retainObjcAccessible
        configuration.retainObjcAnnotated = retainObjcAnnotated
        configuration.indexExclude = Self.sourceFiles.subtracting([testFixturePath]).map { $0.string }
        configuration.resetIndexExcludeMatchers()

        if !testFixturePath.exists {
            fatalError("\(testFixturePath.string) does not exist")
        }

        Self.index()
        try testBlock()
    }

    // MARK: - Private

    private static var _sourceFiles: Set<FilePath>?
    private static var sourceFiles: Set<FilePath> {
        if let files = _sourceFiles {
            return files
        }

        if let driver = driver as? SPMProjectDriver {
            let files = Set(driver.targets.flatMap { $0.sourcePaths }.map { ProjectRootPath.appending($0.string) })
            _sourceFiles = files
            return files
        } else {
            fatalError("Not implemented")
        }
    }
}
