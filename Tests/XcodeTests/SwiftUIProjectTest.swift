@testable import TestShared
@testable import XcodeSupport
import XCTest

// swiftlint:disable:next balanced_xctest_lifecycle
final class SwiftUIProjectTest: SourceGraphTestCase {
    override static func setUp() {
        super.setUp()

        configuration.project = SwiftUIProjectPath.string
        configuration.schemes = ["SwiftUIProject"]
        configuration.targets = ["SwiftUIProject"]

        build(driver: XcodeProjectDriver.self)
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
