import Foundation

public final class XcodeScheme {
    static func make(project: XcodeProjectlike, name: String) throws -> Self {
        return try self.init(project: project, name: name, xcodebuild: inject())
    }

    public let project: XcodeProjectlike
    public let name: String

    private var didPopulate: Bool = false
    private let xcodebuild: Xcodebuild
    private var buildTargetsProperty: [String] = []
    private var testTargetsProperty: [String] = []

    required public init(project: XcodeProjectlike, name: String, xcodebuild: Xcodebuild) throws {
        self.project = project
        self.name = name
        self.xcodebuild = xcodebuild
    }

    public func buildTargets() throws -> [String] {
        try populate()
        return buildTargetsProperty
    }

    public func testTargets() throws -> [String] {
        try populate()
        return testTargetsProperty
    }

    // MARK: - Private

    private func populate() throws {
        guard !didPopulate else { return }

        didPopulate = true
        let settings = try xcodebuild.buildSettings(for: project, scheme: name)
        let parser = XcodebuildSettingsParser(settings: settings)
        buildTargetsProperty = parser.buildTargets(action: "build")
        testTargetsProperty = parser.buildTargets(action: "test")
    }
}

extension XcodeScheme: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension XcodeScheme: Equatable {
    public static func == (lhs: XcodeScheme, rhs: XcodeScheme) -> Bool {
        return lhs.name == rhs.name
    }
}
