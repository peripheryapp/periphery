import Configuration
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
        retainCodableProperties: Bool = false,
        retainEncodableProperties: Bool = false,
        retainUnusedProtocolFuncParams: Bool = false,
        retainAssignOnlyProperties: Bool = false,
        retainAssignOnlyPropertyTypes: [String] = [],
        externalCodableProtocols: [String] = [],
        additionalFilesToIndex: [FilePath] = [],
        externalTestCaseClasses: [String] = [],
        retainFiles: [String] = [],
        testBlock: () throws -> Void
    ) rethrows -> [ScanResult] {
        let configuration = Configuration()
        configuration.retainPublic = retainPublic
        configuration.retainObjcAccessible = retainObjcAccessible
        configuration.retainObjcAnnotated = retainObjcAnnotated
        configuration.retainAssignOnlyProperties = retainAssignOnlyProperties
        configuration.disableRedundantPublicAnalysis = disableRedundantPublicAnalysis
        configuration.externalCodableProtocols = externalCodableProtocols
        configuration.retainCodableProperties = retainCodableProperties
        configuration.retainEncodableProperties = retainEncodableProperties
        configuration.retainUnusedProtocolFuncParams = retainUnusedProtocolFuncParams
        configuration.retainAssignOnlyPropertyTypes = retainAssignOnlyPropertyTypes
        configuration.externalTestCaseClasses = externalTestCaseClasses
        configuration.retainFiles = retainFiles

        if !testFixturePath.exists {
            fatalError("\(testFixturePath.string) does not exist")
        }

        Self.index(sourceFiles: [testFixturePath] + additionalFilesToIndex, configuration: configuration)
        try testBlock()
        return Self.results
    }
}
