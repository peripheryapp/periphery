import Foundation
import PeripheryKit
import ArgumentParser

private let logger = inject(Logger.self)

struct PeripheryCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "periphery",
        subcommands: [ScanCommand.self, CheckUpdateCommand.self, VersionCommand.self]
    )
}

signal(SIGINT) { _ in
    Shell.terminateAll()
    exit(0)
}

do {
    var command = try PeripheryCommand.parseAsRoot()
    try command.run()
} catch {
    if  let error = error as? PeripheryKitError,
        let hint = error.hint {
        logger.hint(hint)
    }
    PeripheryCommand.exit(withError: error)
}
