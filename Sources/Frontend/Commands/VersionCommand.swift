import Foundation
import ArgumentParser

struct VersionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Display this version of Periphery"
    )

    func run() throws {
        print(PeripheryVersion)
    }
}
