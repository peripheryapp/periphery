import XCTest
import SystemPackage
import ArgumentParser
import Commands
import Shared

final class ScanTests: AcceptanceTestCase {
    func testScanWorkspaceWithPath() async throws {
        let project = setupFixture(fixture: .defaultiOSProject)

        do {
            try run(command: ScanCommand.self, arguments: "--project", "\(project)",
                "--schemes", "DefaultiOSProject")
        } catch PeripheryError.xcodeProjectsAreUnsupported {
            #if os(Linux) 
            return
            #endif
        }
        
        XCTOutputDefaultOutputWithoutUnusedCode(scheme: "DefaultiOSProject")
    }
}

