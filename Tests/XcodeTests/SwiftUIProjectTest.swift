import Configuration
@testable import TestShared

final class SwiftUIProjectTest: XcodeSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        let configuration = Configuration()
        configuration.schemes = ["SwiftUIProject"]

        build(projectPath: SwiftUIProjectPath, configuration: configuration)
        index(configuration: configuration)
    }

    func testRetainsMainAppEntryPoint() {
        assertReferenced(.struct("SwiftUIProjectApp"))
    }

    func testDoesNotRetainPreviewProvider() {
        assertNotReferenced(.struct("ContentView_Previews"))
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
