import Foundation

final class BuildPlan {
    static func make(buildLog: String, targets: Set<Target>) throws -> BuildPlan {
        let parser = XcodebuildLogParser(log: buildLog)
        let xcodebuild: Xcodebuild = inject()
        let xcodebuildVersion = XcodebuildVersion.parse(try xcodebuild.version())

        return try BuildPlan(targets: targets,
                             buildLogParser: parser,
                             xcodebuildVersion: xcodebuildVersion,
                             logger: inject())
    }

    private static let excludedArguments = [
        "-Xfrontend",
        "-output-file-map",
        "-parseable-output",
        "-serialize-diagnostics",
        "-incremental",
        "-emit-dependencies"
    ]

    private let buildLogParser: XcodebuildLogParser
    private var invocationsByTarget: [Target: SwiftcInvocation] = [:]
    private var argumentsByTarget: [Target: [String]] = [:]
    private let xcodebuildVersion: String
    private let logger: Logger

    let targets: Set<Target>

    required init(targets: Set<Target>, buildLogParser: XcodebuildLogParser, xcodebuildVersion: String, logger: Logger) throws {
        self.targets = targets
        self.buildLogParser = buildLogParser
        self.xcodebuildVersion = xcodebuildVersion
        self.logger = logger
        self.invocationsByTarget = Dictionary(uniqueKeysWithValues: try targets.map {
            ($0, try self.buildLogParser.getSwiftcInvocation(target: $0.name, module: $0.moduleName))
        })
    }

    func arguments(for target: Target) throws -> [String] {
        if let arguments = argumentsByTarget[target] {
            return arguments
        }

        guard let invocation = invocationsByTarget[target] else {
            throw PeripheryKitError.noSwiftcInvocation(target: target.name)
        }

        let filteredArguments: [BuildArgument]

        if xcodebuildVersion.isVersion(lessThan: "10.0") {
            filteredArguments = invocation.arguments
                .filter { !BuildPlan.excludedArguments.contains($0.key) }
        } else {
            filteredArguments = invocation.arguments
        }

        let arguments = filteredArguments
            .flatMap { [$0.key, $0.value] }
            .compactMap { $0 } + invocation.files
        argumentsByTarget[target] = arguments
        logger.debug("[arguments:'\(target.name)'] \(arguments)")

        return arguments
    }
}
