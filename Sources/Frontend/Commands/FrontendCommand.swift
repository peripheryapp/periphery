import ArgumentParser
import Shared

protocol FrontendCommand: ParsableCommand {}
extension FrontendCommand {
    static var _errorLabel: String { colorize("error", .boldRed) }
}
