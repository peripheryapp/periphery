import ArgumentParser
import Foundation
import Shared

public struct ClearCacheCommand: FrontendCommand {
    public static let configuration = CommandConfiguration(
        commandName: "clear-cache",
        abstract: "Clear Periphery's build cache"
    )
  
    public init() { }

    public func run() throws {
        try Shell.shared.exec(["rm", "-rf", Constants.cachePath().string])
    }
}
