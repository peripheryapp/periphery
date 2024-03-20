import Foundation
import ArgumentParser

struct VersionCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Display the version of Periphery"
    )

    func run() throws {
        print(PeripheryVersion)
    }
}
