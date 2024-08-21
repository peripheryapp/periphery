import Foundation
import Utils

class ShellMock: Shell {
    var output: String = ""

    convenience init() {
        self.init(environment: ProcessInfo.processInfo.environment, logger: Logger())
    }

    override func exec(_: [String], stderr _: Bool = true) throws -> String {
        output
    }
}
