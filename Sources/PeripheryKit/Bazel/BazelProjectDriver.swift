import Foundation
import Shared
import Indexer
import SystemPackage

public class BazelProjectDriver: ProjectDriver {
      public static func build() throws -> Self {
          return self.init()
      }

    // TODO: Others? tvos, watchos, etc
    private static let kinds = [
        "apple_framework_packaging",
        "ios_unit_test",
        "ios_ui_test",
        "ios_application",
//        "swift_binary",
        //"swift_test"
    ]

    private let configuration: Configuration
    private let shell: Shell
    private let logger: Logger
    private let fileManager: FileManager

    private let outputPath = FilePath("/var/tmp/periphery_bazel")

    private lazy var contextLogger: ContextualLogger = {
        logger.contextualized(with: "bazel")
    }()

    required init(
        configuration: Configuration = .shared,
        shell: Shell = .shared,
        logger: Logger = .init(),
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.shell = shell
        self.logger = logger
        self.fileManager = fileManager
    }

    public func build() throws {
        guard let executablePath = Bundle.main.executablePath else {
          fatalError("Expected executable path.")
        }

        try fileManager.createDirectory(at: outputPath.url, withIntermediateDirectories: true)

        // Generic project mode is used for the actual scan.
        configuration.bazel = false
        let configPath = outputPath.appending("periphery.yml")
        try configuration.save(to: configPath)
        contextLogger.debug("Configuration written to \(configPath)")

        let buildPath = outputPath.appending("BUILD")
        let deps = try queryTargets().joined(separator: ",\n")
        let buildFileContents = """
        load("@periphery//bazel/internal:scan.bzl", "scan")

        scan(
          name = "scan",
          testonly = True,
          config = "\(configPath)",
          periphery_binary = "\(executablePath)",
          visibility = [
            "@periphery//bazel:package_group"
          ],
          deps = [
            \(deps)
          ],
        )
        """

        try buildFileContents.write(to: buildPath.url, atomically: true, encoding: .utf8)
        contextLogger.debug("Build file written to \(buildPath)")

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Building...")
        }

        // TODO: Don't throw error, use Bazel exit code.
        // TODO: Only compile.
        try shell.exec([
            "bazel",
            "run",
            "--ui_event_filters=-info,-debug,-warning",
            "@periphery//bazel:scan"],
            captureOutput: false
        )

        // The actual scan is performed by Bazel.
        exit(0)
    }
  
    public func plan(logger: ContextualLogger) throws -> IndexPlan {
        IndexPlan(sourceFiles: [:])
    }

    // MARK: - Private

    private func queryTargets() throws -> [String] {
        try shell
          .exec([
            "bazel",
            "query",
            "--noshow_progress",
            "--ui_event_filters=-info,-debug,-warning",
            query
          ])
          .split(separator: "\n")
          .filter { !$0.hasPrefix("@")} // TODO: Do this in the query.
          .map { "\"@@\($0)\"" }
    }

    private var query: String {
        // TODO: Make configurable.
        // TODO: Add option to filter labels.
        let target = ["//..."]
        let depsExpr = target.map { "deps(\($0))" }.joined(separator: " union ")
        let kindsExpr = "kind('(\(Self.kinds.joined(separator: "|"))) rule', \(depsExpr))"
        return kindsExpr
    }
}
