import XCTest
import PathKit
@testable import PeripheryKit

class SourceKitTest: XCTestCase {
    var project: Project!
    override func setUpWithError() throws {
        self.project = try Project.make(path: PeripheryProjectPath)
    }

    func testWhitespacedFile() throws {
        let mockProjectPath = ProjectRootPath + "Tests/TestEmptyTarget"
        let whitespacedFilePath = mockProjectPath + "File name with space.swift"
        let xcodebuild = Xcodebuild.make()
        try xcodebuild.clearDerivedData(for: project)
        let buildLog = try xcodebuild.build(project: project, scheme: "TestEmptyTarget")
        let target = project.targets.first { $0.name == "TestEmptyTarget" }!
        let buildPlan = try BuildPlan.make(buildLog: buildLog, targets: [target])
        let arguments = try buildPlan.arguments(for: target)
        let sourcekit = SourceKit(arguments: arguments)
        _ = try sourcekit.requestIndex(SourceFile(path: whitespacedFilePath))
    }
}
