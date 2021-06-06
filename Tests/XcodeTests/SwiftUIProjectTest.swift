import XCTest
import PathKit
import Shared
import TestShared
@testable import XcodeSupport
@testable import PeripheryKit

class SwiftUIProjectTest: SourceGraphTestCase {
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

        let project = try! XcodeProject.make(path: SwiftUIProjectPath)

        let configuration: Configuration = inject()
        configuration.outputFormat = .json

        let driver = XcodeProjectDriver(
            logger: inject(),
            configuration: configuration,
            xcodebuild: inject(),
            project: project,
            schemes: [try! XcodeScheme.make(project: project, name: "SwiftUIProject")],
            targets: project.targets
        )

        try! driver.build()
        graph = SourceGraph()
        try! driver.index(graph: graph)
        try! Analyzer.perform(graph: graph)
    }

    func testRetainsMainAppEntryPoint() {
        XCTAssertReferenced((.struct, "SwiftUIProjectApp"))
    }

    func testRetainsPreviewProvider() {
        XCTAssertReferenced((.struct, "ContentView_Previews"))
    }

    func testRetainsLibraryContentProvider() {
        XCTAssertReferenced((.struct, "LibraryViewContent"))
    }
}
