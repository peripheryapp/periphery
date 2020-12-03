import Foundation
import ArgumentParser
import PeripheryKit
import Shared

private let logger = inject(Logger.self)

struct PeripheryCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "periphery",
        subcommands: [ScanCommand.self, CheckUpdateCommand.self, VersionCommand.self]
    )
}

signal(SIGINT) { _ in
    logger.warn("Termination can result in a corrupt index. Try the '--clean-build' flag if you get erroneous results, such as false-positives and incorrect source file locations.")
    let shell: Shell = inject()
    shell.interruptRunning()
    exit(0)
}

do {
    var command = try PeripheryCommand.parseAsRoot()
    try command.run()
} catch {
    if  let error = error as? PeripheryError,
        let hint = error.hint {
        logger.hint(hint)
    }
    PeripheryCommand.exit(withError: error)
}
