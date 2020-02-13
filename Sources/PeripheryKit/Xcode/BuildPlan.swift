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
                return content.split(separator: "\n").map(String.init)
            } else {
                return [arg]
            }
        }
    }
}
