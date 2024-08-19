@testable import TestShared

final class SwiftUIProjectTest: XcodeSourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        configuration.schemes = ["SwiftUIProject"]

        build(projectPath: SwiftUIProjectPath)
        index()
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
