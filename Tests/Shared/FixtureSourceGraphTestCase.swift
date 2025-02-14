@testable import PeripheryKit
import SystemPackage
import XCTest

class FixtureSourceGraphTestCase: SPMSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        build(projectPath: FixturesProjectPath)
    }

    @discardableResult
    func analyze(
        retainPublic: Bool = false,
        retainObjcAccessible: Bool = false,
        retainObjcAnnotated: Bool = false,
        disableRedundantPublicAnalysis: Bool = false,
        additionalFilesToIndex: [FilePath] = [],
        testBlock: () throws -> Void
    ) rethrows -> [ScanResult] {
        configuration.retainPublic = retainPublic
        configuration.retainObjcAccessible = retainObjcAccessible
        configuration.retainObjcAnnotated = retainObjcAnnotated
        configuration.disableRedundantPublicAnalysis = disableRedundantPublicAnalysis
        configuration.resetMatchers()

        if !testFixturePath.exists {
            fatalError("\(testFixturePath.string) does not exist")
        }

        Self.index(sourceFiles: [testFixturePath] + additionalFilesToIndex)
        try testBlock()
        return Self.results
    }
}
