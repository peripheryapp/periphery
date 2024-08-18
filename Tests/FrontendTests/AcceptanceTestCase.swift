import XCTest
import Commands
import SystemPackage
import ArgumentParser
import Shared

enum Fixture: String {
    case defaultiOSProject = "Tests/FrontendTests/DefaultiOSProject/DefaultiOSProject.xcodeproj"
}

class AcceptanceTestCase: XCTestCase {
    let packageRootPath = URL(fileURLWithPath: #file).pathComponents
        .prefix(while: { $0 != "Tests" }).joined(separator: "/").dropFirst()
    
    override class func setUp() {
        Configuration.shared.reset()
        super.setUp()
    }
    
    override class func tearDown() {
        Configuration.shared.reset()
        super.tearDown()
    }
    
    func run(command: FrontendCommand.Type, arguments: String...) throws {
        var command = try command
            .parse(arguments)
        try command.run()
    }

    func setupFixture(fixture: Fixture) -> FilePath {
        var file = FilePath(String(packageRootPath))
        file.append(fixture.rawValue)
        return file
    }
    
    func XCTOutputDefaultOutputWithoutUnusedCode(scheme: String) {
        XCTAssertTrue(LoggerStorage.collectedLogs.contains(
            [
                "* Inspecting project...",
                "* Building \(scheme)...",
                "* Indexing...",
                "* Analyzing...",
                "",
                "* No unused code detected."
            ]
        ))
    }
    
}
