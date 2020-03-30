import Foundation
import ArgumentParser

public struct VersionCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Display this version of Periphery"
    )

    public init() {}

    public func run() throws {
        print(PeripheryVersion)
    }
}
