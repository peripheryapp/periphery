import Foundation

final class BuildPlan {
    static func make(targets: Set<Target>) throws -> BuildPlan {
        let xcodebuild: Xcodebuild = inject()
        let xcodebuildVersion = XcodebuildVersion.parse(try xcodebuild.version())

        return try BuildPlan(targets: targets,
                             xcodebuildVersion: xcodebuildVersion,
                             logger: inject())
    }

    private let xcodebuildVersion: String
    private let logger: Logger

    let targets: Set<Target>

    required init(targets: Set<Target>, xcodebuildVersion: String, logger: Logger) throws {
        self.targets = targets
        self.xcodebuildVersion = xcodebuildVersion
        self.logger = logger
    }
}
