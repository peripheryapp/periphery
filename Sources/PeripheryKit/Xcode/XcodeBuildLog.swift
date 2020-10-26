import Foundation
import PathKit
import CryptoKit

final class XcodeBuildLog {
    static func make(project: XcodeProjectlike, schemes: Set<XcodeScheme>, targets: Set<XcodeTarget>) -> Self {
        return self.init(
            project: project,
            schemes: schemes,
            targets: targets,
            configuration: inject(),
            logger: inject(),
            xcodebuild: inject()
        )
    }

    private let project: XcodeProjectlike
    private let schemes: Set<XcodeScheme>
    private let targets: Set<XcodeTarget>
    private let configuration: Configuration
    private let logger: Logger
    private let xcodebuild: Xcodebuild

    required init(
        project: XcodeProjectlike,
        schemes: Set<XcodeScheme>,
        targets: Set<XcodeTarget>,
        configuration: Configuration,
        logger: Logger,
        xcodebuild: Xcodebuild) {
        self.project = project
        self.schemes = schemes
        self.targets = targets
        self.configuration = configuration
        self.logger = logger
        self.xcodebuild = xcodebuild
    }

    func get() throws -> String {
        var forceSaveKey: String?

        if let key = configuration.useBuildLog {
            if key.hasSuffix(".log") {
                let logPath = Path(key)

                guard logPath.isFile else {
                    throw PeripheryKitError.buildLogError(message: "No build log exists at path: \(logPath.absolute())")
                }

                logger.debug("[xcode:build] Using build log at '\(logPath.absolute())'")
                return try logPath.read()
            }

            if let log = try cache(get: key) {
                logger.debug("[xcode:build] Using saved build log with key '\(key)'")
                return log
            } else {
                logger.warn("No saved build log for the current configuration with the key '\(key)' exists. The build phase will be performed and the build log saved.")
                forceSaveKey = key
            }
        }

        try xcodebuild.clearDerivedData(for: project)
        let log = try build()

        if let key = configuration.saveBuildLog ?? forceSaveKey {
            logger.debug("[xcode:build] Saving build log with key '\(key)'")
            try cache(put: log, userKey: key)
        }

        return log
    }

    // MARK: - Private

    private func build() throws -> String {
        // Ensure test targets are built by chosen schemes
        let allTestTargets = try schemes.flatMap { try $0.testTargets() }
        let testTargetNames = targets.filter { $0.isTestTarget }.map { $0.name }
        let missingTestTargets = Set(testTargetNames).subtracting(allTestTargets)

        if let name = missingTestTargets.first {
            throw PeripheryKitError.testTargetNotBuildable(name: name)
        }

        return try schemes.map {
            if configuration.outputFormat.supportsAuxiliaryOutput {
                let asterisk = colorize("*", .boldGreen)
                logger.info("\(asterisk) Building \($0.name)...")
            }

            let buildForTesting = !Set(try $0.testTargets()).isDisjoint(with: testTargetNames)
            return try xcodebuild.build(project: project,
                                        scheme: $0.name,
                                        additionalArguments: configuration.xcargs,
                                        buildForTesting: buildForTesting)
            }.joined(separator: "\n")
    }

    private func cache(get userKey: String) throws -> String? {
        let key = buildCacheKey(userKey)
        let path = try cachePath() + key

        guard path.isReadable else { return nil }

        return try path.read()
    }

    private func cache(put log: String, userKey: String) throws {
        let key = buildCacheKey(userKey)
        let path = try cachePath() + key
        try path.write(log)
    }

    private func buildCacheKey(_ userKey: String) -> String {
        let targetNames = targets.map { $0.name }.sorted().joined()
        let schemeNames = schemes.map { $0.name }.sorted().joined()
        return "\(userKey)\(targetNames)\(schemeNames)\(project.path.string)".sha1
    }

    func cachePath() throws -> Path {
        let path = try (PeripheryCachePath() + "BuildLogs")
        try path.mkpath()
        return path
    }
}

