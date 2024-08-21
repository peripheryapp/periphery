import ArgumentParser
import BaseLogger

protocol FrontendCommand: ParsableCommand {}
extension FrontendCommand {
    static var _errorLabel: String { colorize("error", .boldRed) }
}
