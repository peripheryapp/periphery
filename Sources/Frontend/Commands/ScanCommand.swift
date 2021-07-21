import Foundation
import ArgumentParser
import Shared

struct ScanCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for unused code"
    )

    private static let defaultConfig = Configuration.make()

    @Argument(help: "Arguments following '--' will be passed to the underlying build tool, which is either 'swift build' or 'xcodebuild' depending on your project")
    var buildArguments: [String] = defaultConfig.buildArguments

    @Flag(help: "Enable guided setup")
    var setup: Bool = defaultConfig.guidedSetup

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    var config: String?

    @Option(help: "Path to your project's .xcworkspace. Xcode projects only")
    var workspace: String?

    @Option(help: "Path to your project's .xcodeproj - supply this option if your project doesn't have an .xcworkspace. Xcode projects only")
    var project: String?

    @Option(help: "Comma-separated list of schemes that must be built in order to produce the targets passed to the --targets option. Xcode projects only", transform: split(by: ","))
    var schemes: [String] = defaultConfig.schemes

    @Option(help: "Comma-separated list of target names to scan. Requied for Xcode projects. Optional for Swift Package Manager projects, default behavior is to scan all targets defined in Package.swift", transform: split(by: ","))
    var targets: [String] = defaultConfig.targets

    @Option(help: "Output format (allowed: \(OutputFormat.allValueStrings.joined(separator: ", ")))")
    var format: OutputFormat = defaultConfig.outputFormat

    @Option(help: "Path glob of source files which should be excluded from indexing. Declarations and references within these files will not be considered during analysis. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var indexExclude: [String] = defaultConfig.indexExclude

    @Option(help: "Path glob of source files which should be excluded from the results. Note that this option is purely cosmetic, these files will still be indexed. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var reportExclude: [String] = defaultConfig.reportExclude

    @Option(help: "Path to index store to use. Implies '--skip-build'")
    var indexStorePath: String?

    @Flag(help: "Retain all public declarations - you'll likely want to enable this if you're scanning a framework/library project")
    var retainPublic: Bool = defaultConfig.retainPublic

    @Flag(help: "Disable identification of redundant public accessibility")
    var disableRedundantPublicAnalysis: Bool = defaultConfig.disableRedundantPublicAnalysis

    @Flag(help: "Retain properties that are assigned, but never used")
    var retainAssignOnlyProperties: Bool = defaultConfig.retainAssignOnlyProperties

    @Option(help: "Comma-separated list of property types to retain if the property is assigned, but never read", transform: split(by: ","))
    var retainAssignOnlyPropertyTypes: [String] = defaultConfig.retainAssignOnlyPropertyTypes

    @Option(help: "Comma-separated list of external protocols that inherit Encodable. Properties of types conforming to these protocols will be retained", transform: split(by: ","))
    var externalEncodableProtocols: [String] = defaultConfig.externalEncodableProtocols

    @Flag(help: "Retain declarations that are exposed to Objective-C implicitly by inheriting NSObject classes, or explicitly with the @objc and @objcMembers attributes")
    var retainObjcAccessible: Bool = defaultConfig.retainObjcAccessible

    @Flag(help: "Retain unused protocol function parameters, even if the parameter is unused in all conforming functions")
    var retainUnusedProtocolFuncParams: Bool = defaultConfig.retainUnusedProtocolFuncParams

    @Flag(help: "Clean existing build artifacts before building")
    var cleanBuild: Bool = defaultConfig.cleanBuild

    @Flag(help: "Skip the project build step")
    var skipBuild: Bool = defaultConfig.skipBuild

    @Flag(help: "Exit with non-zero status if any unused code is found")
    var strict: Bool = defaultConfig.strict

    @Flag(help: "Disable checking for updates")
    var disableUpdateCheck: Bool = defaultConfig.disableUpdateCheck

    @Flag(help: "Enable verbose logging")
    var verbose: Bool = defaultConfig.verbose

    @Flag(help: "Only output results")
    var quiet: Bool = defaultConfig.quiet

    func run() throws {
        let scanBehavior = ScanBehavior.make()

        if !setup {
            try scanBehavior.setup(config).get()
        }

        let configuration = inject(Configuration.self)
        configuration.guidedSetup = setup
        configuration.apply(\.$workspace, workspace)
        configuration.apply(\.$project, project)
        configuration.apply(\.$schemes, schemes)
        configuration.apply(\.$targets, targets)
        configuration.apply(\.$indexExclude, indexExclude)
        configuration.apply(\.$reportExclude, reportExclude)
        configuration.apply(\.$outputFormat, format)
        configuration.apply(\.$retainPublic, retainPublic)
        configuration.apply(\.$retainAssignOnlyProperties, retainAssignOnlyProperties)
        configuration.apply(\.$retainAssignOnlyPropertyTypes, retainAssignOnlyPropertyTypes)
        configuration.apply(\.$retainObjcAccessible, retainObjcAccessible)
        configuration.apply(\.$retainUnusedProtocolFuncParams, retainUnusedProtocolFuncParams)
        configuration.apply(\.$disableRedundantPublicAnalysis, disableRedundantPublicAnalysis)
        configuration.apply(\.$externalEncodableProtocols, externalEncodableProtocols)
        configuration.apply(\.$verbose, verbose)
        configuration.apply(\.$quiet, quiet)
        configuration.apply(\.$disableUpdateCheck, disableUpdateCheck)
        configuration.apply(\.$strict, strict)
        configuration.apply(\.$indexStorePath, indexStorePath)
        configuration.apply(\.$skipBuild, skipBuild)
        configuration.apply(\.$cleanBuild, cleanBuild)
        configuration.apply(\.$buildArguments, buildArguments)

        try scanBehavior.main { project in
            try Scan.make().perform(project: project)
        }.get()
    }

    // MARK: - Private

    private static func split(by delimiter: Character) -> (String?) -> [String] {
        return { options in options?.split(separator: delimiter).map(String.init) ?? [] }
    }
}

extension OutputFormat: ExpressibleByArgument {}
