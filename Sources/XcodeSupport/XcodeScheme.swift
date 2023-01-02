import Foundation
import PeripheryKit
import Shared

final class XcodeScheme {
    let project: XcodeProjectlike
    let name: String

    private var didPopulate: Bool = false
    private let xcodebuild: Xcodebuild
    private var testTargetsProperty: [String] = []

    required init(project: XcodeProjectlike, name: String, xcodebuild: Xcodebuild = .init()) throws {
        self.project = project
        self.name = name
        self.xcodebuild = xcodebuild
    }

    func testTargets() throws -> [String] {
        try populate()
        return testTargetsProperty
    }

    // MARK: - Private

    private func populate() throws {
        guard !didPopulate else { return }

        didPopulate = true
        let settings = try xcodebuild.buildSettings(for: project, scheme: name)
        let parser = XcodebuildSettingsParser(settings: settings)
        testTargetsProperty = parser.buildTargets(action: "test")
    }
}

extension XcodeScheme: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension XcodeScheme: Equatable {
    static func == (lhs: XcodeScheme, rhs: XcodeScheme) -> Bool {
        return lhs.name == rhs.name
    }
}
