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
    var buildArguments: [String] = defaultConfiguration.$buildArguments.defaultValue

    @Flag(help: "Enable guided setup")
    var setup: Bool = defaultConfiguration.guidedSetup

    @Option(help: "Path to the root directory of your project")
    var projectRoot: FilePath = projectRootDefault

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    var config: FilePath?

    @Option(help: "Path to your project's .xcodeproj or .xcworkspace")
    var project: FilePath?

    @Option(parsing: .upToNextOption, help: "Schemes to build. All targets built by these schemes will be scanned")
    var schemes: [String] = defaultConfiguration.$schemes.defaultValue

    @Option(help: "Output format (allowed: \(OutputFormat.allValueStrings.joined(separator: ", ")))")
    var format: OutputFormat = defaultConfiguration.$outputFormat.defaultValue

    @Flag(help: "Exclude test targets from indexing")
    var excludeTests: Bool = defaultConfiguration.$excludeTests.defaultValue

    @Option(parsing: .upToNextOption, help: "Targets to exclude from indexing")
    var excludeTargets: [String] = defaultConfiguration.$excludeTargets.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to exclude from indexing")
    var indexExclude: [String] = defaultConfiguration.$indexExclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to exclude from the results. Note that this option is purely cosmetic, these files will still be indexed")
    var reportExclude: [String] = defaultConfiguration.$reportExclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs to include in the results. This option supersedes '--report-exclude'. Note that this option is purely cosmetic, these files will still be indexed")
    var reportInclude: [String] = defaultConfiguration.$reportInclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Source file globs for which all containing declarations will be retained")
    var retainFiles: [String] = defaultConfiguration.$retainFiles.defaultValue

    @Option(parsing: .upToNextOption, help: "Index store paths. Implies '--skip-build'")
    var indexStorePath: [FilePath] = defaultConfiguration.$indexStorePath.defaultValue

    @Flag(help: "Retain all public declarations, recommended for framework/library projects")
    var retainPublic: Bool = defaultConfiguration.$retainPublic.defaultValue

    @Flag(help: "Disable identification of redundant public accessibility")
    var disableRedundantPublicAnalysis: Bool = defaultConfiguration.$disableRedundantPublicAnalysis.defaultValue

    @Flag(help: "Disable identification of unused imports")
    var disableUnusedImportAnalysis: Bool = defaultConfiguration.$disableUnusedImportAnalysis.defaultValue

    @Flag(help: "Retain properties that are assigned, but never used")
    var retainAssignOnlyProperties: Bool = defaultConfiguration.$retainAssignOnlyProperties.defaultValue

    @Option(parsing: .upToNextOption, help: "Property types to retain if the property is assigned, but never read")
    var retainAssignOnlyPropertyTypes: [String] = defaultConfiguration.$retainAssignOnlyPropertyTypes.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of external protocols that inherit Encodable. Properties and CodingKey enums of types conforming to these protocols will be retained")
    var externalEncodableProtocols: [String] = defaultConfiguration.$externalEncodableProtocols.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of external protocols that inherit Codable. Properties and CodingKey enums of types conforming to these protocols will be retained")
    var externalCodableProtocols: [String] = defaultConfiguration.$externalCodableProtocols.defaultValue

    @Option(parsing: .upToNextOption, help: "Names of XCTestCase subclasses that reside in external targets")
    var externalTestCaseClasses: [String] = defaultConfiguration.$externalTestCaseClasses.defaultValue

    @Flag(help: "Retain declarations that are exposed to Objective-C implicitly by inheriting NSObject classes, or explicitly with the @objc and @objcMembers attributes")
    var retainObjcAccessible: Bool = defaultConfiguration.$retainObjcAccessible.defaultValue

    @Flag(help: "Retain declarations that are exposed to Objective-C explicitly with the @objc and @objcMembers attributes")
    var retainObjcAnnotated: Bool = defaultConfiguration.$retainObjcAnnotated.defaultValue

    @Flag(help: "Retain unused protocol function parameters, even if the parameter is unused in all conforming functions")
    var retainUnusedProtocolFuncParams: Bool = defaultConfiguration.$retainUnusedProtocolFuncParams.defaultValue

    @Flag(help: "Retain SwiftUI previews")
    var retainSwiftUIPreviews: Bool = defaultConfiguration.$retainSwiftUIPreviews.defaultValue

    @Flag(help: "Retain properties on Codable types (including Encodable and Decodable)")
    var retainCodableProperties: Bool = defaultConfiguration.$retainCodableProperties.defaultValue

    @Flag(help: "Retain properties on Encodable types only")
    var retainEncodableProperties: Bool = defaultConfiguration.$retainEncodableProperties.defaultValue

    @Flag(help: "Clean existing build artifacts before building")
    var cleanBuild: Bool = defaultConfiguration.$cleanBuild.defaultValue

    @Flag(help: "Skip the project build step")
    var skipBuild: Bool = defaultConfiguration.$skipBuild.defaultValue

    @Flag(help: "Skip schemes validation")
    var skipSchemesValidation: Bool = defaultConfiguration.$skipSchemesValidation.defaultValue

    @Flag(help: "Output result paths relative to the current directory")
    var relativeResults: Bool = defaultConfiguration.$relativeResults.defaultValue

    @Flag(help: "Exit with non-zero status if any unused code is found")
    var strict: Bool = defaultConfiguration.$strict.defaultValue

    @Flag(help: "Disable checking for updates")
    var disableUpdateCheck: Bool = defaultConfiguration.$disableUpdateCheck.defaultValue

    @Flag(help: "Enable verbose logging")
    var verbose: Bool = defaultConfiguration.$verbose.defaultValue

    @Flag(help: "Only output results")
    var quiet: Bool = defaultConfiguration.$quiet.defaultValue

    @Option(help: "JSON package manifest path (obtained using `swift package describe --type json` or manually)")
    var jsonPackageManifestPath: FilePath?

    @Option(help: "Baseline file path used to filter results")
    var baseline: FilePath?

    @Option(help: "Baseline file path where results are written. Pass the same path to '--baseline' in subsequent scans to exclude the results recorded in the baseline.")
    var writeBaseline: FilePath?

    @Option(help: "Project configuration for non-Apple build systems")
    var genericProjectConfig: FilePath?

    @Flag(help: "Enable Bazel project mode")
    var bazel: Bool = defaultConfiguration.$bazel.defaultValue

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

        if let output = try configuration.outputFormat.formatter.init(configuration: configuration).format(filteredResults) {
            if configuration.outputFormat.supportsAuxiliaryOutput {
                logger.info("", canQuiet: true)
            }

            logger.info(output, canQuiet: false)
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

extension FilePath: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}
