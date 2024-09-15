import ArgumentParser
import Foundation
import Logger
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
    let logger = Logger()
    logger.warn(
        "Termination can result in a corrupt index. Try the '--clean-build' flag if you get erroneous results such as false-positives and incorrect source file locations.",
        newlinePrefix: true // Print a newline after ^C
    )
    ShellProcessStore.shared.interruptRunning()
    exit(0)
}

do {
    var command = try PeripheryCommand.parseAsRoot()
    do {
        try command.run()
    } catch let error as PeripheryError {
        throw error
    } catch {
        throw PeripheryError.underlyingError(error)
    }
} catch {
    PeripheryCommand.exit(withError: error)
}
