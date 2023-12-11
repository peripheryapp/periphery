import Foundation
import ArgumentParser
import SystemPackage
import Shared

struct ScanCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for unused code"
    )

    @Argument(help: "Arguments following '--' will be passed to the underlying build tool, which is either 'swift build' or 'xcodebuild' depending on your project")
    var buildArguments: [String] = defaultConfiguration.$buildArguments.defaultValue

    @Flag(help: "Enable guided setup")
    var setup: Bool = defaultConfiguration.guidedSetup

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    var config: String?

    @Option(help: "Path to your project's .xcworkspace. Xcode projects only")
    var workspace: String?

    @Option(help: "Path to your project's .xcodeproj - supply this option if your project doesn't have an .xcworkspace. Xcode projects only")
    var project: String?

    @Option(parsing: .upToNextOption, help: "Path to file targets mapping. For use with third-party build systems. Multiple paths may be specified")
    var fileTargetsPath: [FilePath] = defaultConfiguration.$fileTargetsPath.defaultValue

    @Option(help: "Comma-separated list of schemes that must be built in order to produce the targets passed to the --targets option. Xcode projects only", transform: split(by: ","))
    var schemes: [String] = defaultConfiguration.$schemes.defaultValue

    @Option(help: "Comma-separated list of target names to scan. Required for Xcode projects. Optional for Swift Package Manager projects, default behavior is to scan all targets defined in Package.swift", transform: split(by: ","))
    var targets: [String] = defaultConfiguration.$targets.defaultValue

    @Option(help: "Output format (allowed: \(OutputFormat.allValueStrings.joined(separator: ", ")))")
    var format: OutputFormat = defaultConfiguration.$outputFormat.defaultValue

    @Option(help: "Path glob of source files to exclude from indexing. Declarations and references within these files will not be considered during analysis. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var indexExclude: [String] = defaultConfiguration.$indexExclude.defaultValue

    @Option(help: "Path glob of source files to exclude from the results. Note that this option is purely cosmetic, these files will still be indexed. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var reportExclude: [String] = defaultConfiguration.$reportExclude.defaultValue

    @Option(help: "Path glob of source files to include in the results. This option supersedes '--report-exclude'. Note that this option is purely cosmetic, these files will still be indexed. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var reportInclude: [String] = defaultConfiguration.$reportInclude.defaultValue

    @Option(parsing: .upToNextOption, help: "Path to the index store. Multiple paths may be specified. Implies '--skip-build'")
    var indexStorePath: [FilePath] = defaultConfiguration.$indexStorePath.defaultValue

    @Flag(help: "Retain all public declarations, recommended for framework/library projects")
    var retainPublic: Bool = defaultConfiguration.$retainPublic.defaultValue

    @Flag(help: "Disable identification of redundant public accessibility")
    var disableRedundantPublicAnalysis: Bool = defaultConfiguration.$disableRedundantPublicAnalysis.defaultValue

    @Flag(help: "Enable identification of unused imports (experimental)")
    var enableUnusedImportAnalysis: Bool = defaultConfiguration.$enableUnusedImportsAnalysis.defaultValue

    @Flag(help: "Retain properties that are assigned, but never used")
    var retainAssignOnlyProperties: Bool = defaultConfiguration.$retainAssignOnlyProperties.defaultValue

    @Option(help: "Comma-separated list of property types to retain if the property is assigned, but never read", transform: split(by: ","))
    var retainAssignOnlyPropertyTypes: [String] = defaultConfiguration.$retainAssignOnlyPropertyTypes.defaultValue

    @Option(help: "Comma-separated list of external protocols that inherit Encodable. Properties of types conforming to these protocols will be retained", transform: split(by: ","))
    var externalEncodableProtocols: [String] = defaultConfiguration.$externalEncodableProtocols.defaultValue

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

    @Flag(help: "Clean existing build artifacts before building")
    var cleanBuild: Bool = defaultConfiguration.$cleanBuild.defaultValue

    @Flag(help: "Skip the project build step")
    var skipBuild: Bool = defaultConfiguration.$skipBuild.defaultValue

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

    private static let defaultConfiguration = Configuration()

    func run() throws {
        let scanBehavior = ScanBehavior()

        if !setup {
            try scanBehavior.setup(config).get()
        }

        let configuration = Configuration.shared
        configuration.guidedSetup = setup
        configuration.apply(\.$workspace, workspace)
        configuration.apply(\.$project, project)
        configuration.apply(\.$fileTargetsPath, fileTargetsPath)
        configuration.apply(\.$schemes, schemes)
        configuration.apply(\.$targets, targets)
        configuration.apply(\.$indexExclude, indexExclude)
        configuration.apply(\.$reportExclude, reportExclude)
        configuration.apply(\.$reportInclude, reportInclude)
        configuration.apply(\.$outputFormat, format)
        configuration.apply(\.$retainPublic, retainPublic)
        configuration.apply(\.$retainAssignOnlyProperties, retainAssignOnlyProperties)
        configuration.apply(\.$retainAssignOnlyPropertyTypes, retainAssignOnlyPropertyTypes)
        configuration.apply(\.$retainObjcAccessible, retainObjcAccessible)
        configuration.apply(\.$retainObjcAnnotated, retainObjcAnnotated)
        configuration.apply(\.$retainUnusedProtocolFuncParams, retainUnusedProtocolFuncParams)
        configuration.apply(\.$retainSwiftUIPreviews, retainSwiftUIPreviews)
        configuration.apply(\.$disableRedundantPublicAnalysis, disableRedundantPublicAnalysis)
        configuration.apply(\.$enableUnusedImportsAnalysis, enableUnusedImportAnalysis)
        configuration.apply(\.$externalEncodableProtocols, externalEncodableProtocols)
        configuration.apply(\.$externalTestCaseClasses, externalTestCaseClasses)
        configuration.apply(\.$verbose, verbose)
        configuration.apply(\.$quiet, quiet)
        configuration.apply(\.$disableUpdateCheck, disableUpdateCheck)
        configuration.apply(\.$strict, strict)
        configuration.apply(\.$indexStorePath, indexStorePath)
        configuration.apply(\.$skipBuild, skipBuild)
        configuration.apply(\.$cleanBuild, cleanBuild)
        configuration.apply(\.$buildArguments, buildArguments)
        configuration.apply(\.$relativeResults, relativeResults)

        try scanBehavior.main { project in
            try Scan().perform(project: project)
        }.get()
    }

    // MARK: - Private

    private static func split(by delimiter: Character) -> (String?) -> [String] {
        return { options in options?.split(separator: delimiter).map(String.init) ?? [] }
    }
}

extension OutputFormat: ExpressibleByArgument {}

extension FilePath: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}
