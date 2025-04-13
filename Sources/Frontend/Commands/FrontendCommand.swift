import ArgumentParser
import Logger

protocol FrontendCommand: ParsableCommand {}
extension FrontendCommand {
    static var _errorLabel: String { Logger.colorize("error", .boldRed) }
}
