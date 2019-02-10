import Foundation
import Commandant
import PeripheryKit

private let logger = inject(Logger.self)
private let registry = CommandRegistry<PeripheryKitError>()

registry.register(ScanCommand())
registry.register(ScanSyntaxCommand())
registry.register(CheckUpdateCommand())
registry.register(VersionCommand())

let helpCommand = PeripheryKit.HelpCommand(registry: registry)
registry.register(helpCommand)

signal(SIGINT) { _ in
    Shell.terminateAll()
    exit(0)
}

registry.main(defaultVerb: helpCommand.verb) { error in
    logger.error(error)

    if let hint = error.hint {
        logger.hint(hint)
    }
}
