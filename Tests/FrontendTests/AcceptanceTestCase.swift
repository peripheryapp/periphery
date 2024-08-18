import XCTest
import Commands
import ArgumentParser
import Shared
import System


public enum Fixture: String {
    case defaultiOSProject = "Tests/FrontendTests/DefaultiOSProject/DefaultiOSProject.xcodeproj"
}

public class AcceptanceTestCase: XCTestCase {
    let packageRootPath = URL(fileURLWithPath: #file).pathComponents
        .prefix(while: { $0 != "Tests" }).joined(separator: "/").dropFirst()
    
    public override class func setUp() {
        Configuration.shared.reset()
        super.setUp()
    }
    
    public override class func tearDown() {
        Configuration.shared.reset()
        super.tearDown()
    }
    
    public func run(command: FrontendCommand.Type, arguments: String...) throws {
        var command = try command
            .parse(arguments)
        try command.run()
    }

    public func setupFixture(fixture: Fixture) -> FilePath {
        var file = FilePath(String(packageRootPath))
        file.append(fixture.rawValue)
        return file
    }
    
    public func XCTOutputDefaultOutputWithoutUnusedCode(scheme: String) {
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
