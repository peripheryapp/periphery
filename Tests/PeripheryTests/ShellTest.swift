import Logger
@testable import Shared
import XCTest

final class ShellTest: XCTestCase {
    func testPristineEnvironmentWithPreservedVariables() {
        let path = "/path/to/bin"
        let developerDir = "/path/to/Xcode.app/Contents/Developer"
        let environment = [
            "PATH": path,
            "DEVELOPER_DIR": developerDir,
        ]
        let logger = Logger(quiet: true)
        let shell = Shell(environment: environment, logger: logger)
        XCTAssertEqual(shell.pristineEnvironment["PATH"], path)
        XCTAssertEqual(shell.pristineEnvironment["DEVELOPER_DIR"], developerDir)
    }
}
