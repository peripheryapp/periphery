import XCTest
import PathKit
import Shared
import TestShared
@testable import PeripheryKit

class SPMProjectTest: SourceGraphTestCase {
    static private var graph: SourceGraph!

    override var graph: SourceGraph! {
        get {
            Self.graph
        }
        set {
            Self.graph = newValue
        }
    }

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
        XCTAssertReferenced((.functionFree, "main()"))
    }

    func testCrossModuleReference() {
        XCTAssertReferenced((.class, "PublicCrossModuleReferenced"))
        XCTAssertNotReferenced((.class, "PublicCrossModuleNotReferenced"))
    }
}
