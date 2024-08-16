import ArgumentParser
import Foundation
import Frontend

public struct VersionCommand: FrontendCommand {
    public static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Display the version of Periphery"
    )

  public init() { }

    public func run() throws {
        print(PeripheryVersion)
    }
}
