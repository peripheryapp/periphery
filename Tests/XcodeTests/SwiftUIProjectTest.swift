import XCTest
import Shared
@testable import TestShared
@testable import XcodeSupport
@testable import PeripheryKit

class SwiftUIProjectTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        let project = try! XcodeProject.make(path: SwiftUIProjectPath)

        let driver = XcodeProjectDriver(
            logger: inject(),
            configuration: configuration,
            xcodebuild: inject(),
            project: project,
            schemes: [try! XcodeScheme.make(project: project, name: "SwiftUIProject")],
            targets: project.targets
        )

        try! driver.build()
        try! driver.index(graph: graph)
        try! Analyzer.perform(graph: graph)
    }

    func testRetainsMainAppEntryPoint() {
        assertReferenced(.struct("SwiftUIProjectApp"))
    }

    func testRetainsPreviewProvider() {
        assertReferenced(.struct("ContentView_Previews"))
    }

    func testRetainsLibraryContentProvider() {
        assertReferenced(.struct("LibraryViewContent"))
    }
}
