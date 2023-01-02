import Foundation
import ArgumentParser
import Shared

struct ClearCacheCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear-cache",
        abstract: "Clear Periphery's build cache"
    )

    func run() throws {
        try Shell.shared.exec(["rm", "-rf", Constants.cachePath().string])
    }
}
