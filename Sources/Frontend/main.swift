import ArgumentParser
import Foundation
import Logger
import Shared

// When stdout is a pipe, enable line buffering so output is flushed after each
// newline rather than block-buffered, ensuring timely output to the consumer.
var info = stat()
fstat(STDOUT_FILENO, &info)

if (info.st_mode & S_IFMT) == S_IFIFO {
    setlinebuf(stdout)
    setlinebuf(stderr)
}

struct PeripheryCommand: ParsableCommand {
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
    let logger = Logger(quiet: false, verbose: false, coloredOutputEnabled: false)
    logger.warn(
        "Termination can result in a corrupt index. Try the '--clean-build' flag if you get erroneous results such as false-positives and incorrect source file locations.",
        newlinePrefix: true // Print a newline after ^C
    )
    ShellProcessStore.shared.interruptRunning()
    exit(0)
}

do {
    var command = try PeripheryCommand.parseAsRoot()
    try command.run()
} catch {
    PeripheryCommand.exit(withError: error)
}
