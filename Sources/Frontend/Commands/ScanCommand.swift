import ArgumentParser
import Configuration
import Foundation
import Logger
import PeripheryKit
import Shared
import SystemPackage

struct ScanCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for unused code"
    )

    @Argument(help: "Arguments following '--' will be passed to the underlying build tool, which is either 'swift build' or 'xcodebuild' depending on your project")
    var buildArguments: [String] = Configuration.Default.buildArguments

    @Flag(help: "Enable guided setup")
    var setup: Bool = Configuration.Default.guidedSetup

    @Option(help: "Path to the root directory of your project")
    var projectRoot: FilePath = projectRootDefault

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    var config: FilePath?

    @Option(help: "Path to your project's .xcodeproj or .xcworkspace")
    var project: FilePath?

    @Option(parsing: .upToNextOption, help: "Schemes to build. All targets built by these schemes will be scanned")
    var schemes: [String] = Configuration.Default.schemes

    @Option(help: "Output format (allowed: \(OutputFormat.allValueStrings.joined(separator: ", ")))")
    var format: OutputFormat = Configuration.Default.outputFormat

    @Flag(help: "Exclude test targets from indexing")
    var excludeTests: Bool = Configuration.Default.excludeTests

    @Option(parsing: .upToNextOption, help: "Targets to exclude from indexing")
    var excludeTargets: [String] = Configuration.Default.excludeTargets

    @Option(parsing: .upToNextOption, help: "Source file globs to exclude from indexing")
    var indexExclude: [String] = Configuration.Default.indexExclude

    @Option(parsing: .upToNextOption, help: "Source file globs to exclude from the results. Note that this option is purely cosmetic, these files will still be indexed")
    var reportExclude: [String] = Configuration.Default.reportExclude

    @Option(parsing: .upToNextOption, help: "Source file globs to include in the results. This option supersedes '--report-exclude'. Note that this option is purely cosmetic, these files will still be indexed")
    var reportInclude: [String] = Configuration.Default.reportInclude

    @Option(parsing: .upToNextOption, help: "Source file globs for which all containing declarations will be retained")
    var retainFiles: [String] = Configuration.Default.retainFiles

    @Option(parsing: .upToNextOption, help: "Index store paths. Implies '--skip-build'")
    var indexStorePath: [FilePath] = Configuration.Default.indexStorePath

    @Flag(help: "Retain all public declarations, recommended for framework/library projects")
    var retainPublic: Bool = Configuration.Default.retainPublic

    @Flag(help: "Disable identification of redundant public accessibility")
    var disableRedundantPublicAnalysis: Bool = Configuration.Default.disableRedundantPublicAnalysis

    @Flag(help: "Disable identification of unused imports")
    var disableUnusedImportAnalysis: Bool = Configuration.Default.disableUnusedImportAnalysis

    @Flag(help: "Retain properties that are assigned, but never used")
    var retainAssignOnlyProperties: Bool = Configuration.Default.retainAssignOnlyProperties

    @Option(parsing: .upToNextOption, help: "Property types to retain if the property is assigned, but never read")
    var retainAssignOnlyPropertyTypes: [String] = Configuration.Default.retainAssignOnlyPropertyTypes

    @Option(parsing: .upToNextOption, help: "Names of external protocols that inherit Encodable. Properties and CodingKey enums of types conforming to these protocols will be retained")
    var externalEncodableProtocols: [String] = Configuration.Default.externalEncodableProtocols

    @Option(parsing: .upToNextOption, help: "Names of external protocols that inherit Codable. Properties and CodingKey enums of types conforming to these protocols will be retained")
    var externalCodableProtocols: [String] = Configuration.Default.externalCodableProtocols

    @Option(parsing: .upToNextOption, help: "Names of XCTestCase subclasses that reside in external targets")
    var externalTestCaseClasses: [String] = Configuration.Default.externalTestCaseClasses

    @Flag(help: "Retain declarations that are exposed to Objective-C implicitly by inheriting NSObject classes, or explicitly with the @objc and @objcMembers attributes")
    var retainObjcAccessible: Bool = Configuration.Default.retainObjcAccessible

    @Flag(help: "Retain declarations that are exposed to Objective-C explicitly with the @objc and @objcMembers attributes")
    var retainObjcAnnotated: Bool = Configuration.Default.retainObjcAnnotated

    @Flag(help: "Retain unused protocol function parameters, even if the parameter is unused in all conforming functions")
    var retainUnusedProtocolFuncParams: Bool = Configuration.Default.retainUnusedProtocolFuncParams

    @Flag(help: "Retain SwiftUI previews")
    var retainSwiftUIPreviews: Bool = Configuration.Default.retainSwiftUIPreviews

    @Flag(help: "Retain properties on Codable types (including Encodable and Decodable)")
    var retainCodableProperties: Bool = Configuration.Default.retainCodableProperties

    @Flag(help: "Retain properties on Encodable types only")
    var retainEncodableProperties: Bool = Configuration.Default.retainEncodableProperties

    @Flag(help: "Clean existing build artifacts before building")
    var cleanBuild: Bool = Configuration.Default.cleanBuild

    @Flag(help: "Skip the project build step")
    var skipBuild: Bool = Configuration.Default.skipBuild

    @Flag(help: "Skip schemes validation")
    var skipSchemesValidation: Bool = Configuration.Default.skipSchemesValidation

    @Flag(help: "Output result paths relative to the current directory")
    var relativeResults: Bool = Configuration.Default.relativeResults

    @Flag(help: "Exit with non-zero status if any unused code is found")
    var strict: Bool = Configuration.Default.strict

    @Flag(help: "Disable checking for updates")
    var disableUpdateCheck: Bool = Configuration.Default.disableUpdateCheck

    @Flag(help: "Enable verbose logging")
    var verbose: Bool = Configuration.Default.verbose

    @Flag(help: "Only output results")
    var quiet: Bool = Configuration.Default.quiet

    @Option(help: "JSON package manifest path (obtained using `swift package describe --type json` or manually)")
    var jsonPackageManifestPath: FilePath?

    @Option(help: "Baseline file path used to filter results")
    var baseline: FilePath?

    @Option(help: "Baseline file path where results are written. Pass the same path to '--baseline' in subsequent scans to exclude the results recorded in the baseline.")
    var writeBaseline: FilePath?

    @Option(help: "File path where formatted results are written.")
    var writeResults: FilePath?

    @Option(help: "Project configuration for non-Apple build systems")
    var genericProjectConfig: FilePath?

    @Flag(help: "Enable Bazel project mode")
    var bazel: Bool = Configuration.Default.bazel

    @Option(help: "Filter pattern applied to the Bazel top-level targets query")
    var bazelFilter: String?

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
        configuration.apply(\.$project, project)
        configuration.apply(\.$schemes, schemes)
        configuration.apply(\.$indexExclude, indexExclude)
        configuration.apply(\.$reportExclude, reportExclude)
        configuration.apply(\.$reportInclude, reportInclude)
        configuration.apply(\.$outputFormat, format)
        configuration.apply(\.$retainFiles, retainFiles)
        configuration.apply(\.$retainPublic, retainPublic)
        configuration.apply(\.$retainAssignOnlyProperties, retainAssignOnlyProperties)
        configuration.apply(\.$retainAssignOnlyPropertyTypes, retainAssignOnlyPropertyTypes)
        configuration.apply(\.$retainObjcAccessible, retainObjcAccessible)
        configuration.apply(\.$retainObjcAnnotated, retainObjcAnnotated)
        configuration.apply(\.$retainUnusedProtocolFuncParams, retainUnusedProtocolFuncParams)
        configuration.apply(\.$retainSwiftUIPreviews, retainSwiftUIPreviews)
        configuration.apply(\.$disableRedundantPublicAnalysis, disableRedundantPublicAnalysis)
        configuration.apply(\.$disableUnusedImportAnalysis, disableUnusedImportAnalysis)
        configuration.apply(\.$externalEncodableProtocols, externalEncodableProtocols)
        configuration.apply(\.$externalCodableProtocols, externalCodableProtocols)
        configuration.apply(\.$externalTestCaseClasses, externalTestCaseClasses)
        configuration.apply(\.$verbose, verbose)
        configuration.apply(\.$quiet, quiet)
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

        let logger = Logger(
            quiet: configuration.quiet,
            verbose: configuration.verbose
        )
        logger.contextualized(with: "version").debug(PeripheryVersion)
        let shell = Shell(logger: logger)
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
                .flatMapSet { $0.usrs }
                .union(baseline?.usrs ?? [])
            let baseline = Baseline.v1(usrs: usrs.sorted())
            let data = try JSONEncoder().encode(baseline)
            try data.write(to: baselinePath.url)
        }

        let outputFormat = configuration.outputFormat
        let formatter = outputFormat.formatter.init(configuration: configuration)

        if let output = try formatter.format(filteredResults, colored: outputFormat.supportsColoredOutput) {
            if outputFormat.supportsAuxiliaryOutput {
                logger.info("", canQuiet: true)
            }

            logger.info(output, canQuiet: false)

            if !filteredResults.isEmpty, let resultsPath = configuration.writeResults {
                var output = output

                if outputFormat.supportsColoredOutput {
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

extension FilePath: ArgumentParser.ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}
