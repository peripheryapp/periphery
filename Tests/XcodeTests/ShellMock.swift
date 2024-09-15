import Foundation
import Shared

class ShellMock: Shell {
    var output: String = ""

    convenience init() {
        let configuration = Configuration()
        let logger = Logger(configuration: configuration)
        self.init(environment: ProcessInfo.processInfo.environment, logger: logger)
    }

    override func exec(_: [String], stderr _: Bool = true) throws -> String {
        output
    }
}
