import Foundation
import Commandant
import PeripheryKit
import ArgumentParser

private let logger = inject(Logger.self)

struct PeripheryCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "periphery",
        subcommands: [CheckUpdateCommand.self]
    )
}
private let registry = CommandRegistry<PeripheryKitError>()

registry.register(ScanCommand())
registry.register(ScanSyntaxCommand())
registry.register(CheckUpdateCommand())
registry.register(VersionCommand())

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
