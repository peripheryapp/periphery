import XCTest
import Shared
@testable import TestShared
@testable import XcodeSupport
@testable import PeripheryKit

class SwiftUIProjectTest: SourceGraphTestCase {
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
