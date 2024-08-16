import XCTest
import PathKit
import SystemPackage
import ArgumentParser
import Commands
import Shared

final class ScanTests: XCTestCase {
  fileprivate let packageRootPath = URL(fileURLWithPath: #file).pathComponents
      .prefix(while: { $0 != "Tests" }).joined(separator: "/").dropFirst()

  func testScanWorkspaceWithPath() async throws {
    var file = FilePath(String(packageRootPath))
    
    file.append(FilePath.Component("fixtures"))
    file.append(FilePath.Component("DefaultiOSProject"))
    file.append(FilePath.Component("DefaultiOSProject.xcodeproj"))
    
    let command = try ScanCommand.parse(
      [
        "--project", "\(file.url.path())",
        "--schemes", "DefaultiOSProject"
      ]
    )
    try command.run()
    
    XCTAssertTrue(LoggerStorage.collectedLogs.contains(
      [
        "* Inspecting project...",
        "* Building DefaultiOSProject...",
        "* Indexing...",
        "* Analyzing...",
        "",
        "* No unused code detected."
      ]
    )
    )
  }
}
 
