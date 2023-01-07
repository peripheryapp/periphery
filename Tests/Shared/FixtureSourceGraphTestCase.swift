import SystemPackage
@testable import PeripheryKit

class FixtureSourceGraphTestCase: SourceGraphTestCase {
    class override func setUp() {
        super.setUp()
        _sourceFiles = nil
    }

    func analyze(retainPublic: Bool = false,
                 retainObjcAccessible: Bool = false,
                 testBlock: () throws -> Void
    ) rethrows {
        configuration.retainPublic = retainPublic
        configuration.retainObjcAccessible = retainObjcAccessible
        configuration.indexExcludeSourceFiles = Self.sourceFiles.subtracting([testFixturePath])
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
