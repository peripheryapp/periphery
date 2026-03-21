#if os(macOS)
    import Configuration
    import Foundation
    import ProjectDrivers
    import SystemPackage
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
                self.assertReferenced(.functionMethodInstance("privateExtensionTapped(_:)"))
                self.assertReferenced(.varInstance("button"))
                self.assertReferenced(.varInstance("borderWidth"))
                // Unreferenced - not connected in XIB
                self.assertNotReferenced(.varInstance("unusedMacOutlet"))
                self.assertNotReferenced(.functionMethodInstance("unusedMacAction(_:)"))
                self.assertNotReferenced(.functionMethodInstance("unusedPrivateExtensionAction(_:)"))
                self.assertNotReferenced(.varInstance("unusedMacInspectable"))
            }
        }
    }

    final class SPMProjectMacOSFilesystemIBDiscoveryTest: SPMSourceGraphTestCase {
        override static func setUp() {
            super.setUp()
            build(projectPath: SPMProjectMacOSPath)
        }

        func testDiscoversInterfaceBuilderFilesWithoutDeclaredResources() throws {
            let manifestJSON = """
            {
              "targets": [
                {
                  "name": "SPMProjectMacOSKit",
                  "type": "regular",
                  "path": "Sources/SPMProjectMacOSKit"
                },
                {
                  "name": "Frontend",
                  "type": "executable",
                  "path": "Sources/Frontend"
                }
              ]
            }
            """

            let manifestURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("json")
            try manifestJSON.write(to: manifestURL, atomically: true, encoding: .utf8)
            defer {
                try? FileManager.default.removeItem(at: manifestURL)
            }

            let planConfiguration = Configuration()
            planConfiguration.jsonPackageManifestPath = FilePath(manifestURL.path)

            try SPMProjectMacOSPath.chdir {
                let driver = try SPMProjectDriver(
                    configuration: planConfiguration,
                    shell: Self.shell,
                    logger: Self.logger
                )
                Self.plan = try driver.plan(logger: Self.logger.contextualized(with: "index"))
            }

            let expectedXibPath = SPMProjectMacOSPath
                .appending("Sources/SPMProjectMacOSKit/Resources/SPMXibViewController.xib")
            XCTAssertTrue(Self.plan.xibPaths.contains(expectedXibPath))

            index(configuration: Configuration())

            assertReferenced(.class("SPMXibViewController")) {
                self.assertReferenced(.functionMethodInstance("buttonTapped(_:)"))
                self.assertReferenced(.functionMethodInstance("privateExtensionTapped(_:)"))
            }
        }
    }
#endif
