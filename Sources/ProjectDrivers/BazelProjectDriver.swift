import Configuration
import Foundation
import Logger
import Shared
import SystemPackage

public class BazelProjectDriver: ProjectDriver {
    public static var isSupported: Bool {
        FilePath("MODULE.bazel").exists || FilePath("WORKSPACE").exists
    }

    private static let topLevelKinds = [
        // rules_apple, iOS
        "ios_app_clip",
        "ios_application",
        "ios_extension",
        "ios_imessage_application",
        "ios_imessage_extension",
        "ios_sticker_pack_extension",
        "ios_ui_test",
        "ios_unit_test",

        // rules_apple, tvOS
        "tvos_application",
        "tvos_extension",
        "tvos_ui_test",
        "tvos_unit_test",

        // rules_apple, watchOS
        "watchos_application",
        "watchos_extension",
        "watchos_ui_test",
        "watchos_unit_test",

        // rules_apple, visionOS
        "visionos_application",
        "visionos_ui_test",
        "visionos_unit_test",

        // rules_apple, macOS
        "macos_application",
        "macos_command_line_application",
        "macos_extension",
        "macos_kernel_extension",
        "macos_quick_look_plugin",
        "macos_spotlight_importer",
        "macos_xpc_service",
        "macos_ui_test",
        "macos_unit_test",

        // rules_swift
        "swift_binary",
        "swift_test",
        "swift_compiler_plugin",
    ]

    private let configuration: Configuration
    private let shell: Shell
    private let logger: Logger
    private let fileManager: FileManager

    private let outputPath = FilePath("/var/tmp/periphery_bazel")

    private lazy var contextLogger: ContextualLogger = logger.contextualized(with: "bazel")

    public required init(
        configuration: Configuration,
        shell: Shell,
        logger: Logger,
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

        let configPath = outputPath.appending("periphery.yml")
        configuration.bazel = false // Generic project mode is used for the actual scan.
        configuration.reportExclude.append("**/bazel-out/**/*")
        try configuration.save(to: configPath)
        contextLogger.debug("Configuration written to \(configPath)")

        let buildPath = outputPath.appending("BUILD.bazel")
        let deps = try queryTargets().joined(separator: ",\n")
        let buildFileContents = """
        load("@periphery//bazel:rules.bzl", "scan")

        scan(
          name = "scan",
          testonly = True,
          config = "\(configPath)",
          periphery_binary = "\(executablePath)",
          visibility = [
            "@periphery//:package_group"
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

        let status = try shell.execStatus([
            "bazel",
            "run",
            "--check_visibility=false",
            "--ui_event_filters=-info,-debug,-warning",
            "\(generatedRepositoryName)//rule:scan",
        ])

        // The actual scan is performed by Bazel.
        exit(status)
    }

    // MARK: - Private

    private var generatedRepositoryName: String {
        fileManager.fileExists(atPath: ".bazel_use_local_generated_repo") ? "@periphery_generated" : "@@periphery++generated+periphery_generated"
    }

    private func queryTargets() throws -> [String] {
        try shell
            .exec(["bazel", "query", query], stderr: false)
            .split(separator: "\n")
            .map { "\"@@\($0)\"" }
    }

    private var query: String {
        let query = """
        filter(
          '^//.*',
          kind(
            '(\(Self.topLevelKinds.joined(separator: "|"))) rule',
            deps(//...)
          )
        )
        """

        if let pattern = configuration.bazelFilter {
            return "filter('\(pattern)', \(query))"
        }

        return query
    }
}
