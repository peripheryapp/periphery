import ArgumentParser
import Logger

protocol FrontendCommand: ParsableCommand {}
extension FrontendCommand {
    static var _errorLabel: String { logger.colorize("error", .boldRed) }
}
