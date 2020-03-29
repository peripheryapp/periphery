import Foundation
import ArgumentParser

public struct VersionCommand: ParsableCommand {
    public let verb = "version"
    public let function = "Display this version of Periphery"

    public init() {}

    public func run() throws {
        print(PeripheryVersion)
    }
}
