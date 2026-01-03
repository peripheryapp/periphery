import Foundation
import Logger
import Shared

class ShellMock: Shell {
    var output: String = ""

    convenience init() {
        let logger = Logger(quiet: true, verbose: false, coloredOutputEnabled: false)
        self.init(logger: logger)
    }

    override func exec(_: [String]) throws -> String {
        output
    }
}
