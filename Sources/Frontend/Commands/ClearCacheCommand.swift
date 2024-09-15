import ArgumentParser
import Foundation
import Shared

struct ClearCacheCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear-cache",
        abstract: "Clear Periphery's build cache"
    )

    func run() throws {
        let configuration = Configuration()
        let logger = Logger(configuration: configuration)
        let shell = Shell(logger: logger)
        try shell.exec(["rm", "-rf", Constants.cachePath().string])
    }
}
