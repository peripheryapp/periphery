import ArgumentParser
import Foundation
import Shared

Logger.configureBuffering()

struct PeripheryCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "periphery",
        subcommands: [
            ScanCommand.self,
            CheckUpdateCommand.self,
            ClearCacheCommand.self,
            VersionCommand.self,
        ]
    )
}

signal(SIGINT) { _ in
    let logger = Logger(configuration: Configuration())
    logger.warn(
        "Termination can result in a corrupt index. Try the '--clean-build' flag if you get erroneous results such as false-positives and incorrect source file locations.",
        newlinePrefix: true // Print a newline after ^C
    )
    let shell = Shell(logger: logger)
    shell.interruptRunning()
    exit(0)
}

do {
    var command = try PeripheryCommand.parseAsRoot()
    try command.run()
} catch {
    PeripheryCommand.exit(withError: error)
}
