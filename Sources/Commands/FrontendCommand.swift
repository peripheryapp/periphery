import ArgumentParser
import Shared

public protocol FrontendCommand: ParsableCommand {}
public extension FrontendCommand {
    static var _errorLabel: String { colorize("error", .boldRed) }
}
