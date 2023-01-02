import Foundation
import ArgumentParser
import PeripheryKit
import Shared

Logger.configureBuffering()

struct PeripheryCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "periphery",
        subcommands: [ScanCommand.self, CheckUpdateCommand.self, VersionCommand.self]
    )
}

signal(SIGINT) { _ in
    let logger = Logger()
    logger.warn("Termination can result in a corrupt index. Try the '--clean-build' flag if you get erroneous results, such as false-positives and incorrect source file locations.")
    Shell.shared.interruptRunning()
    exit(0)
}

do {
    var command = try PeripheryCommand.parseAsRoot()
    try command.run()
} catch {
    PeripheryCommand.exit(withError: error)
}
