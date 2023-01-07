import XCTest
import Shared
@testable import TestShared
@testable import XcodeSupport
@testable import PeripheryKit

class SwiftUIProjectTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        let project = try! XcodeProject(path: SwiftUIProjectPath)

        let driver = XcodeProjectDriver(
            configuration: configuration,
            project: project,
            schemes: [try! XcodeScheme(project: project, name: "SwiftUIProject")],
            targets: project.targets,
            packageTargets: [:]
        )

        try! driver.build()
        try! driver.index(graph: graph)
        try! SourceGraphMutatorRunner.perform(graph: graph)
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

    func testRetainsUIApplicationDelegateAdaptorProperty() {
        assertReferenced(.struct("SwiftUIProjectApp")) {
            self.assertReferenced(.varInstance("appDelegate"))
        }
    }

    func testRetainsUIApplicationDelegateAdaptorReferencedType() {
        assertReferenced(.class("AppDelegate"))
    }
}
