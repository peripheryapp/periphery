import Foundation

final class XcodeBuildPlan {
    static func make(buildLog: String, targets: Set<XcodeTarget>) throws -> XcodeBuildPlan {
        let parser = XcodebuildLogParser(log: buildLog)
        let xcodebuild: Xcodebuild = inject()
        let xcodebuildVersion = XcodebuildVersion.parse(try xcodebuild.version())

        return try XcodeBuildPlan(targets: targets,
                                  buildLogParser: parser,
                                  xcodebuildVersion: xcodebuildVersion,
                                  logger: inject())
    }

    static func make(targets: Set<XcodeTarget>) throws -> XcodeBuildPlan {
        let xcodebuild: Xcodebuild = inject()
        let xcodebuildVersion = XcodebuildVersion.parse(try xcodebuild.version())

        return try XcodeBuildPlan(targets: targets,
                                  buildLogParser: nil,
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

    private var invocationsByTarget: [XcodeTarget: SwiftcInvocation] = [:]
    private var argumentsByTarget: [XcodeTarget: [String]] = [:]
    private let xcodebuildVersion: String
    private let logger: Logger

    let targets: Set<XcodeTarget>

    required init(targets: Set<XcodeTarget>, buildLogParser: XcodebuildLogParser?, xcodebuildVersion: String, logger: Logger) throws {
        self.targets = targets
        self.xcodebuildVersion = xcodebuildVersion
        self.logger = logger
        // For legacy mode indexing with SourceKit
        if let buildLogParser = buildLogParser {
            self.invocationsByTarget = Dictionary(uniqueKeysWithValues: try targets.map {
                ($0, try buildLogParser.getSwiftcInvocation(target: $0.name, module: $0.moduleName))
            })
        }
    }

    func arguments(for target: XcodeTarget) throws -> [String] {
        if let arguments = argumentsByTarget[target] {
            return arguments
        }

        guard let invocation = invocationsByTarget[target] else {
            throw PeripheryKitError.noSwiftcInvocation(target: target.name)
        }

        let filteredArguments: [XcodeBuildArgument]

        if xcodebuildVersion.isVersion(lessThan: "10.0") {
            filteredArguments = invocation.arguments
                .filter { !XcodeBuildPlan.excludedArguments.contains($0.key) }
        } else {
            filteredArguments = invocation.arguments
        }

        let rawArguments = filteredArguments
            .flatMap { [$0.key, $0.value] }
            .compactMap { $0 } + invocation.files
        let arguments = try expandResponseFiles(rawArguments)
        argumentsByTarget[target] = arguments
        logger.debug("[arguments:'\(target.name)'] \(arguments)")

        return arguments
    }

    // Swift compiler expands arguments when a file starting with '@' is given just after `main`.
    // But sourcekitd doesn't expand that, so we need to expand it manually.
    // References:
    // - https://github.com/apple/swift/blob/master/tools/driver/driver.cpp#L215
    // - https://github.com/llvm/llvm-project/blob/master/llvm/lib/Support/CommandLine.cpp#L1112
    fileprivate func expandResponseFiles(_ arguments: [String]) throws -> [String] {
        return try arguments.flatMap { arg -> [String] in
            if arg.starts(with: "@") {
                let filepath = String(arg.dropFirst())
                let content = try String(contentsOfFile: filepath)
                return content.split(separator: "\n").map(sanitizeFilePath)
            } else {
                return [arg]
            }
        }
    }
}
