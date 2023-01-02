import XCTest
@testable import Shared

final class ShellTest: XCTestCase {
    func testPristineEnvironmentWithPreservedVariables() {
        let path = "/path/to/bin"
        let developerDir = "/path/to/Xcode.app/Contents/Developer"
        let environment = [
            "PATH": path,
            "DEVELOPER_DIR": developerDir
        ]
        let shell = Shell(environment: environment, logger: .init())
        XCTAssertEqual(shell.pristineEnvironment["PATH"], path)
        XCTAssertEqual(shell.pristineEnvironment["DEVELOPER_DIR"], developerDir)
    }
}
