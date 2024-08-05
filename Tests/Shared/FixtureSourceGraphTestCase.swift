import SystemPackage
@testable import PeripheryKit
import XCTest

class FixtureSourceGraphTestCase: SPMSourceGraphTestCase {
    static override func setUp() {
        super.setUp()

        build(projectPath: FixturesProjectPath)
    }

    @discardableResult
    func analyze(retainPublic: Bool = false,
                 retainObjcAccessible: Bool = false,
                 retainObjcAnnotated: Bool = false,
                 disableRedundantPublicAnalysis: Bool = false,
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

        Self.index(sourceFile: testFixturePath)
        try testBlock()
        return Self.results
    }
}
