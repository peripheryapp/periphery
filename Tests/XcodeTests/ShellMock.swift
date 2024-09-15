import Foundation
import Logger
import Shared

class ShellMock: Shell {
    var output: String = ""

    convenience init() {
        let logger = Logger(quiet: true)
        self.init(environment: ProcessInfo.processInfo.environment, logger: logger)
    }

    override func exec(_: [String], stderr _: Bool = true) throws -> String {
        output
    }
}
