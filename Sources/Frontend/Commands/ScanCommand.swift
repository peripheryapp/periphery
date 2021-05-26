import Foundation
import ArgumentParser
import PathKit
import Shared

struct ScanCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for unused code"
    )

    @Argument(help: "Arguments following '--' will be passed to the underlying build tool, which is either 'swift build' or 'xcodebuild' depending on your project")
    var buildArguments: [String] = []

    @Flag(help: "Enable guided setup")
    var setup: Bool = false

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    var config: String?

    @Option(help: "Path to your project's .xcworkspace. Xcode projects only")
    var workspace: String?

    @Option(help: "Path to your project's .xcodeproj - supply this option if your project doesn't have an .xcworkspace. Xcode projects only")
    var project: String?

    @Option(help: "Comma separatered list of schemes that must be built in order to produce the targets passed to the --targets option. Xcode projects only", transform: split(by: ","))
    var schemes: [String] = []

    @Option(help: "Comma separatered list of target names to scan. Requied for Xcode projects. Optional for Swift Package Manager projects, default behavior is to scan all targets defined in Package.swift", transform: split(by: ","))
    var targets: [String] = []

    @Option(help: "Output format, available formatters are: \(OutputFormat.allCases.map { $0.rawValue }.joined(separator: ", "))")
    var format: String?

    @Option(help: "Path glob of source files which should be excluded from indexing. Declarations and references within these files will not be considered during analysis. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var indexExclude: [String] = []

    @Option(help: "Path glob of source files which should be excluded from the results. Note that this option is purely cosmetic, these files will still be indexed. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var reportExclude: [String] = []

    @Option(help: "Path to index store to use. Automatically defaults to the correct store for your project")
    var indexStorePath: String?

    @Flag(help: "Retain all public declarations - you'll likely want to enable this if you're scanning a framework/library project")
    var retainPublic: Bool = false

    @Flag(help: "Disable identification of redundant public accessibility")
    var disableRedundantPublicAnalysis: Bool = false

    @Flag(help: "Retain properties that are assigned, but never used")
    var retainAssignOnlyProperties: Bool = false

    @Option(help: "Comma separatered list of property types to retain if the property is assigned, but never read", transform: split(by: ","))
    var retainAssignOnlyPropertyTypes: [String] = []

    @Flag(help: "Retain declarations that are exposed to Objective-C implicitly by inheriting NSObject classes, or explicitly with the @objc and @objcMembers attributes")
    var retainObjcAccessible: Bool = false

    @Flag(help: "Retain unused protocol function parameters, even if the parameter is unused in all conforming functions")
    var retainUnusedProtocolFuncParams: Bool = false

    @Flag(help: "Clean existing build artifacts before building")
    var cleanBuild: Bool = false

    @Flag(help: "Skip the project build step")
    var skipBuild: Bool = false

    @Flag(help: "Exit with non-zero status if any unused code is found")
    var strict: Bool = false

    @Flag(help: "Disable checking for updates")
    var disableUpdateCheck: Bool = false

    @Flag(help: "Enable verbose logging")
    var verbose: Bool = false

    @Flag(help: "Only output results")
    var quiet: Bool = false

    func run() throws {
        let scanBehavior = ScanBehavior.make()

        try scanBehavior.setup(config).get()

        let configuration = inject(Configuration.self)

        if workspace != nil {
            configuration.workspace = workspace
        }

        if project != nil {
            configuration.project = project
        }

        if !indexExclude.isEmpty {
            configuration.indexExclude = indexExclude
        }

        if !reportExclude.isEmpty {
            configuration.reportExclude = reportExclude
        }

        if !targets.isEmpty {
            configuration.targets = targets
        }

        if !schemes.isEmpty {
            configuration.schemes = schemes
        }

        if !buildArguments.isEmpty {
            configuration.buildArguments = buildArguments
        }

        if let formatName = format {
            configuration.outputFormat = try OutputFormat.make(named: formatName)
        }

        if let indexStorePath = indexStorePath {
            configuration.indexStorePath = indexStorePath
        }

        if isExplicit("retain-public") {
            configuration.retainPublic = retainPublic
        }

        if isExplicit("retain-assign-only-properties") {
            configuration.retainAssignOnlyProperties = retainAssignOnlyProperties
        }

        if !retainAssignOnlyPropertyTypes.isEmpty {
            configuration.retainAssignOnlyPropertyTypes = retainAssignOnlyPropertyTypes
        }

        if isExplicit("retain-objc-accessible") {
            configuration.retainObjcAccessible = retainObjcAccessible
        }

        if isExplicit("retain-unused-protocol-func-params") {
            configuration.retainUnusedProtocolFuncParams = retainUnusedProtocolFuncParams
        }

        if isExplicit("disable-redundant-public-analysis") {
            configuration.disableRedundantPublicAnalysis = disableRedundantPublicAnalysis
        }

        if isExplicit("skip-build") {
            configuration.skipBuild = skipBuild
        }

        if isExplicit("clean-build") {
            configuration.cleanBuild = cleanBuild
        }

        if isExplicit("disable-update-check") {
            configuration.updateCheck = !disableUpdateCheck
        }

        if isExplicit("verbose") {
            configuration.verbose = verbose
        }

        if isExplicit("quiet") {
            configuration.quiet = quiet
        }

        if isExplicit("strict") {
            configuration.strict = strict
        }

        configuration.guidedSetup = setup

        try scanBehavior.main { project in
            try Scan.make().perform(project: project)
        }.get()
    }

    // MARK: - Private

    private func isExplicit(_ arg: String) -> Bool {
        CommandLine.arguments.contains { $0.hasSuffix(arg) }
    }

    // Not referenced in Swift 5.2, but fixed in 5.3.
    // periphery:ignore
    fileprivate static func split(by delimiter: Character) -> (String?) -> [String] {
        return { options in options?.split(separator: delimiter).map(String.init) ?? [] }
    }
}
