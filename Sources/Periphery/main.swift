import Foundation
import Commandant
import PeripheryKit
import ArgumentParser

private let logger = inject(Logger.self)

struct PeripheryCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "periphery",
        subcommands: [ScanCommand.self, CheckUpdateCommand.self, VersionCommand.self]
    )
}
private let registry = CommandRegistry<PeripheryKitError>()

registry.register(ScanSyntaxCommand())
registry.register(CheckUpdateCommand())

signal(SIGINT) { _ in
    Shell.terminateAll()
    exit(0)
}

PeripheryCommand.main()
//registry.main(defaultVerb: helpCommand.verb) { error in
//    logger.error(error)
//
//    if let hint = error.hint {
//        logger.hint(hint)
//    }
//}
