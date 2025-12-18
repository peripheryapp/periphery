#if os(macOS)
    @testable import TestShared
    import XCTest

    final class AppIntentsRetentionTest: FixtureSourceGraphTestCase {
        func testRetainsAppIntent() {
            analyze {
                assertReferenced(.struct("SimpleIntent"))
            }
        }

        func testRetainsAppEntity() {
            analyze {
                assertReferenced(.struct("SimpleEntity"))
                assertReferenced(.struct("SimpleEntityQuery"))
            }
        }

        func testRetainsAppEnum() {
            analyze {
                assertReferenced(.enum("SimpleAppEnum"))
            }
        }

        func testRetainsAppShortcutsProvider() {
            analyze {
                assertReferenced(.struct("SimpleShortcutsProvider"))
            }
        }
    }
#endif
