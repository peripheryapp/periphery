#if os(macOS)
    import Configuration
    @testable import TestShared
    import XCTest

    final class SPMProjectMacOSTest: SPMSourceGraphTestCase {
        override static func setUp() {
            super.setUp()

            build(projectPath: SPMProjectMacOSPath)
            index(configuration: Configuration())
        }

        func testRetainsInterfaceBuilderDeclarations() {
            assertReferenced(.class("SPMXibViewController")) {
                // Referenced via XIB (connected)
                self.assertReferenced(.functionMethodInstance("buttonTapped(_:)"))
                self.assertReferenced(.varInstance("button"))
                // Unreferenced - not connected in XIB
                self.assertNotReferenced(.varInstance("unusedMacOutlet"))
                self.assertNotReferenced(.functionMethodInstance("unusedMacAction(_:)"))
            }
        }
    }
#endif
