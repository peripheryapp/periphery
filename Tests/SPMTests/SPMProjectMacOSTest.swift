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
                self.assertReferenced(.functionMethodInstance("buttonTapped(_:)"))
                self.assertReferenced(.varInstance("button"))
            }
        }
    }
#endif
