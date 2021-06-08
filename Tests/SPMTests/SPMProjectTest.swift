import XCTest
import PathKit
import Shared
@testable import TestShared
@testable import PeripheryKit

class SPMProjectTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        let configuration: Configuration = inject()
        configuration.outputFormat = .json

        SPMProjectPath.chdir {
            let package = try! SPM.Package.load()
            let driver = SPMProjectDriver(
                package: package,
                targets: package.targets,
                configuration: configuration,
                logger: inject()
            )

            try! driver.build()
            graph = SourceGraph()
            try! driver.index(graph: graph)
            try! Analyzer.perform(graph: graph)
        }
    }

    func testMainEntryFile() {
        assertReferenced(.functionFree("main()"))
    }

    func testCrossModuleReference() {
        assertReferenced(.class("PublicCrossModuleReferenced"))
        assertNotReferenced(.class("PublicCrossModuleNotReferenced"))
    }
}
