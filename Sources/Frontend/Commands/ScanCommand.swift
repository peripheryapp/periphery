import ArgumentParser
import Configuration
import Foundation
import Logger
import PeripheryKit
import Shared
import SystemPackage

struct ScanCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for unused code"
    )

    @Argument(help: "Arguments following '--' will be passed to the underlying build tool, which is either 'swift build' or 'xcodebuild' depending on your project")
    private var buildArguments: [String] = defaultConfiguration.$buildArguments.defaultValue

    @Flag(help: "Enable guided setup")
    private var setup: Bool = defaultConfiguration.guidedSetup

    @Option(help: "Path to the root directory of your project")
    private var projectRoot: FilePath = projectRootDefault

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    private var config: FilePath?

    @Option(help: "Path to your project's .xcodeproj or .xcworkspace")
    private var project: FilePath?

    @Option(parsing: .upToNextOption, help: "Schemes to build. All targets built by these schemes will be scanned")
    private var schemes: [String] = defaultConfiguration.$schemes.defaultValue

    @Option(help: "Output format")
    private var format: OutputFormat = defaultConfiguration.$outputFormat.defaultValue

    @Flag(help: "Exclude test targets from indexing")
    private var excludeTests: Bool = defaultConfiguration.$excludeTests.defaultValue

    @Option(parsing: .upToNextOption, help: "Targets to exclude from indexing")
    private var excludeTargets: [String] = defaultConfiguration.$excludeTargets.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to exclude from indexing")
    private var indexExclude: [String] = defaultConfiguration.$indexExclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to exclude from the results. Note that this option is purely cosmetic, these files will still be indexed")
    private var reportExclude: [String] = defaultConfiguration.$reportExclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to include in the results. This option supersedes '--report-exclude'. Note that this option is purely cosmetic, these files will still be indexed")
    private var reportInclude: [String] = defaultConfiguration.$reportInclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs for which all containing declarations will be retained")
    private var retainFiles: [String] = defaultConfiguration.$retainFiles.defaultValue

    @Option(parsing: .upToNextOption, help: "Index store paths. Implies '--skip-build'")
    private var indexStorePath: [FilePath] = defaultConfiguration.$indexStorePath.defaultValue

    @Flag(help: "Retain all public declarations, recommended for framework/library projects")
    private var retainPublic: Bool = defaultConfiguration.$retainPublic.defaultValue

    @Option(parsing: .upToNextOption, help: "Public SPIs (System Programming Interfaces) to check for unused code even when '--retain-public' is enabled")
    private var noRetainSPI: [String] = defaultConfiguration.$noRetainSPI.defaultValue

    @Flag(help: "Disable identification of redundant public accessibility")
    private var disableRedundantPublicAnalysis: Bool = defaultConfiguration.$disableRedundantPublicAnalysis.defaultValue

    @Flag(help: "Disable identification of redundant internal accessibility")
    private var disableRedundantInternalAnalysis: Bool = defaultConfiguration.$disableRedundantInternalAnalysis.defaultValue

    @Flag(help: "Disable identification of redundant fileprivate accessibility")
    private var disableRedundantFilePrivateAnalysis: Bool = defaultConfiguration.$disableRedundantFilePrivateAnalysis.defaultValue

    @Flag(help: "Show redundant internal/fileprivate accessibility warnings for nested declarations even when the containing type is already flagged")
    private var showNestedRedundantAccessibility: Bool = defaultConfiguration.$showNestedRedundantAccessibility.defaultValue

    @Flag(help: "Disable identification of unused imports")
    private var disableUnusedImportAnalysis: Bool = defaultConfiguration.$disableUnusedImportAnalysis.defaultValue

    @Flag(inversion: .prefixedNo, help: "Report superfluous ignore comments")
    private var superfluousIgnoreComments: Bool = defaultConfiguration.$superfluousIgnoreComments.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of unused imported modules to retain")
    private var retainUnusedImportedModules: [String] = defaultConfiguration.$retainUnusedImportedModules.defaultValue

    @Flag(help: "Retain properties that are assigned, but never used")
    private var retainAssignOnlyProperties: Bool = defaultConfiguration.$retainAssignOnlyProperties.defaultValue

    @Option(parsing: .upToNextOption, help: "Property types to retain if the property is assigned, but never read")
    private var retainAssignOnlyPropertyTypes: [String] = defaultConfiguration.$retainAssignOnlyPropertyTypes.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of external protocols that inherit Encodable. Properties and CodingKey enums of types conforming to these protocols will be retained")
    private var externalEncodableProtocols: [String] = defaultConfiguration.$externalEncodableProtocols.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of external protocols that inherit Codable. Properties and CodingKey enums of types conforming to these protocols will be retained")
    private var externalCodableProtocols: [String] = defaultConfiguration.$externalCodableProtocols.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of XCTestCase subclasses that reside in external targets")
    private var externalTestCaseClasses: [String] = defaultConfiguration.$externalTestCaseClasses.defaultValue

    @Flag(help: "Retain declarations that are exposed to Objective-C implicitly by inheriting NSObject classes, or explicitly with the @objc and @objcMembers attributes")
    private var retainObjcAccessible: Bool = defaultConfiguration.$retainObjcAccessible.defaultValue

    @Flag(help: "Retain declarations that are exposed to Objective-C explicitly with the @objc and @objcMembers attributes")
    private var retainObjcAnnotated: Bool = defaultConfiguration.$retainObjcAnnotated.defaultValue

    @Flag(help: "Retain unused protocol function parameters, even if the parameter is unused in all conforming functions")
    private var retainUnusedProtocolFuncParams: Bool = defaultConfiguration.$retainUnusedProtocolFuncParams.defaultValue

    @Flag(help: "Retain SwiftUI previews")
    private var retainSwiftUIPreviews: Bool = defaultConfiguration.$retainSwiftUIPreviews.defaultValue

    @Flag(help: "Retain properties on Codable types (including Encodable and Decodable)")
    private var retainCodableProperties: Bool = defaultConfiguration.$retainCodableProperties.defaultValue

    @Flag(help: "Retain properties on Encodable types only")
    private var retainEncodableProperties: Bool = defaultConfiguration.$retainEncodableProperties.defaultValue

    @Flag(help: "Clean existing build artifacts before building")
    private var cleanBuild: Bool = defaultConfiguration.$cleanBuild.defaultValue

    @Flag(help: "Skip the project build step")
    private var skipBuild: Bool = defaultConfiguration.$skipBuild.defaultValue

    @Flag(help: "Skip schemes validation")
    private var skipSchemesValidation: Bool = defaultConfiguration.$skipSchemesValidation.defaultValue

    @Flag(help: "Output result paths relative to the current directory")
    private var relativeResults: Bool = defaultConfiguration.$relativeResults.defaultValue

    @Flag(help: "Exit with non-zero status if any unused code is found")
    private var strict: Bool = defaultConfiguration.$strict.defaultValue

    @Flag(help: "Disable checking for updates")
    private var disableUpdateCheck: Bool = defaultConfiguration.$disableUpdateCheck.defaultValue

    @Flag(help: "Enable verbose logging")
    private var verbose: Bool = defaultConfiguration.$verbose.defaultValue

    @Flag(help: "Only output results")
    private var quiet: Bool = defaultConfiguration.$quiet.defaultValue

    @Option(help: "Colored output mode")
    private var color: ColorOption = defaultConfiguration.$color.defaultValue

    @Flag(name: .customLong("no-color"), help: .hidden)
    private var noColor: Bool = false

    @Option(help: "JSON package manifest path (obtained using `swift package describe --type json` or manually)")
    private var jsonPackageManifestPath: FilePath?

    @Option(help: "Baseline file path used to filter results")
    private var baseline: FilePath?

    @Option(help: "Baseline file path where results are written. Pass the same path to '--baseline' in subsequent scans to exclude the results recorded in the baseline.")
    private var writeBaseline: FilePath?

    @Option(help: "File path where formatted results are written.")
    private var writeResults: FilePath?

    @Option(help: "Project configuration for non-Apple build systems")
    private var genericProjectConfig: FilePath?

    @Flag(help: "Enable Bazel project mode")
    private var bazel: Bool = defaultConfiguration.$bazel.defaultValue

    @Option(help: "Filter pattern applied to the Bazel top-level targets query")
    private var bazelFilter: String?

    @Option(help: "Path to a global index store populated by Bazel. If provided, will be used instead of individual module stores.")
    private var bazelIndexStore: FilePath?

    private static let defaultConfiguration = Configuration()

    func run() throws {
        if !FileManager.default.changeCurrentDirectoryPath(projectRoot.string) {
            throw PeripheryError.changeCurrentDirectoryFailed(projectRoot)
        }

        let configuration = Configuration()

        if !setup {
            try configuration.load(from: config)
        }

        configuration.guidedSetup = setup
        configuration.projectRoot = projectRoot
        configuration.apply(\.$project, project)
        configuration.apply(\.$schemes, schemes)
        configuration.apply(\.$indexExclude, indexExclude)
        configuration.apply(\.$reportExclude, reportExclude)
        configuration.apply(\.$reportInclude, reportInclude)
        configuration.apply(\.$outputFormat, format)
        configuration.apply(\.$retainFiles, retainFiles)
        configuration.apply(\.$retainPublic, retainPublic)
        configuration.apply(\.$noRetainSPI, noRetainSPI)
        configuration.apply(\.$retainAssignOnlyProperties, retainAssignOnlyProperties)
        configuration.apply(\.$retainAssignOnlyPropertyTypes, retainAssignOnlyPropertyTypes)
        configuration.apply(\.$retainObjcAccessible, retainObjcAccessible)
        configuration.apply(\.$retainObjcAnnotated, retainObjcAnnotated)
        configuration.apply(\.$retainUnusedProtocolFuncParams, retainUnusedProtocolFuncParams)
        configuration.apply(\.$retainSwiftUIPreviews, retainSwiftUIPreviews)
        configuration.apply(\.$disableRedundantPublicAnalysis, disableRedundantPublicAnalysis)
        configuration.apply(\.$disableRedundantInternalAnalysis, disableRedundantInternalAnalysis)
        configuration.apply(\.$disableRedundantFilePrivateAnalysis, disableRedundantFilePrivateAnalysis)
        configuration.apply(\.$showNestedRedundantAccessibility, showNestedRedundantAccessibility)
        configuration.apply(\.$disableUnusedImportAnalysis, disableUnusedImportAnalysis)
        configuration.apply(\.$superfluousIgnoreComments, superfluousIgnoreComments)
        configuration.apply(\.$retainUnusedImportedModules, retainUnusedImportedModules)
        configuration.apply(\.$externalEncodableProtocols, externalEncodableProtocols)
        configuration.apply(\.$externalCodableProtocols, externalCodableProtocols)
        configuration.apply(\.$externalTestCaseClasses, externalTestCaseClasses)
        configuration.apply(\.$verbose, verbose)
        configuration.apply(\.$quiet, quiet)
        configuration.apply(\.$color, noColor ? .never : color)
        configuration.apply(\.$disableUpdateCheck, disableUpdateCheck)
        configuration.apply(\.$strict, strict)
        configuration.apply(\.$indexStorePath, indexStorePath)
        configuration.apply(\.$skipBuild, skipBuild)
        configuration.apply(\.$excludeTests, excludeTests)
        configuration.apply(\.$excludeTargets, excludeTargets)
        configuration.apply(\.$skipSchemesValidation, skipSchemesValidation)
        configuration.apply(\.$cleanBuild, cleanBuild)
        configuration.apply(\.$buildArguments, buildArguments)
        configuration.apply(\.$relativeResults, relativeResults)
        configuration.apply(\.$retainCodableProperties, retainCodableProperties)
        configuration.apply(\.$retainEncodableProperties, retainEncodableProperties)
        configuration.apply(\.$jsonPackageManifestPath, jsonPackageManifestPath)
        configuration.apply(\.$baseline, baseline)
        configuration.apply(\.$writeBaseline, writeBaseline)
        configuration.apply(\.$writeResults, writeResults)
        configuration.apply(\.$genericProjectConfig, genericProjectConfig)
        configuration.apply(\.$bazel, bazel)
        configuration.apply(\.$bazelFilter, bazelFilter)
        configuration.apply(\.$bazelIndexStore, bazelIndexStore)

        configuration.buildFilenameMatchers()

        let logger = Logger(configuration: configuration)
        logger.contextualized(with: "version").debug(PeripheryVersion)
        let shell = ShellImpl(logger: logger) {
            logger.warn(
                "Termination can result in a corrupt index. Try the '--clean-build' flag if you get erroneous results such as false-positives and incorrect source file locations.",
                newlinePrefix: true // Print a newline after ^C
            )
        }
        let swiftVersion = SwiftVersion(shell: shell)
        logger.debug(swiftVersion.fullVersion)
        try swiftVersion.validateVersion()

        if swiftVersion.version.isVersion(equalTo: "6.1"), !retainAssignOnlyProperties {
            logger.warn("Assign-only property analysis is disabled with Swift 6.1 due to a Swift bug: https://github.com/swiftlang/swift/issues/80394.")
            configuration.retainAssignOnlyProperties = true
        }

        let project: Project = if configuration.guidedSetup {
            try GuidedSetup(configuration: configuration, shell: shell, logger: logger).perform()
        } else {
            try Project(configuration: configuration, shell: shell, logger: logger)
        }

        let updateChecker = UpdateChecker(logger: logger, configuration: configuration)
        updateChecker.run()

        let results = try Scan(
            configuration: configuration,
            logger: logger,
            swiftVersion: swiftVersion
        ).perform(project: project)

        let interval = logger.beginInterval("result:output")
        var baseline: Baseline?

        if let baselinePath = configuration.baseline {
            let data = try Data(contentsOf: baselinePath.url)
            baseline = try JSONDecoder().decode(Baseline.self, from: data)
        }

        let filteredResults = try OutputDeclarationFilter(configuration: configuration, logger: logger).filter(results, with: baseline)

        if let baselinePath = configuration.writeBaseline {
            let usrs = filteredResults
                .filter(\.includeInBaseline)
                .flatMapSet { $0.usrs }
                .union(baseline?.usrs ?? [])
            let baseline = Baseline.v1(usrs: usrs.sorted())
            let data = try JSONEncoder().encode(baseline)
            try data.write(to: baselinePath.url)
        }

        let outputFormat = configuration.outputFormat
        let formatter = outputFormat.formatter.init(configuration: configuration, logger: logger)
        let colored = outputFormat.supportsColoredOutput && logger.isColoredOutputEnabled

        if let output = try formatter.format(filteredResults, colored: colored) {
            if outputFormat.supportsAuxiliaryOutput {
                logger.info("", canQuiet: true)
            }

            logger.info(output, canQuiet: false)

            if !filteredResults.isEmpty, let resultsPath = configuration.writeResults {
                var output = output

                if colored {
                    // The formatted output contains ANSI escape codes, so we need to re-format
                    // with coloring disabled.
                    output = try formatter.format(filteredResults, colored: false) ?? ""
                }

                try output.write(to: resultsPath.url, atomically: true, encoding: .utf8)
            }
        }

        logger.endInterval(interval)

        updateChecker.notifyIfAvailable()

        if !filteredResults.isEmpty, configuration.strict {
            throw PeripheryError.foundIssues(count: filteredResults.count)
        }
    }

    // MARK: - Private

    private static var projectRootDefault: FilePath {
        let bazelWorkspace = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"]
        let root = bazelWorkspace ?? FileManager.default.currentDirectoryPath
        return FilePath(root)
    }
}

extension OutputFormat: ExpressibleByArgument {}
extension ColorOption: ExpressibleByArgument {}

extension FilePath: ArgumentParser.ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}
