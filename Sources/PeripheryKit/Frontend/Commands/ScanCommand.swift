import Foundation
import ArgumentParser
import PathKit

public struct ScanCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for unused code"
    )

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

    @Flag(inversion: .prefixedNo, help: "Retain all public declarations - you'll likely want to enable this if you're scanning a framework/library project")
    var retainPublic: Bool?

    @Flag(inversion: .prefixedNo, help: "Don't retain declarations that are exposed to Objective-C by inheriting NSObject, or explicitly with the @objc and @objcMembers annotations")
    var retainObjcAnnotated: Bool?

    @Flag(inversion: .prefixedNo, help: "Retain unused protocol function parameters, even if the parameter is unused in all conforming functions")
    var retainUnusedProtocolFuncParams: Bool?

    @Option(help: "Output format, available formatters are: \(OutputFormat.allCases.map { $0.rawValue }.joined(separator: ", "))")
    var format: String?

    @Option(help: "Path glob of source files which should be excluded from indexing. Declarations and references within these files will not be considered during analysis. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var indexExclude: [String] = []

    @Option(help: "Path glob of source files which should be excluded from the results. Note that this option is purely cosmetic, these files will still be indexed. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var reportExclude: [String] = []

    @Flag(inversion: .prefixedNo, help: "Enable verbose logging")
    var verbose: Bool?

    @Flag(inversion: .prefixedNo, help: "Only output results")
    var quiet: Bool?

    @Flag(inversion: .prefixedNo, help: "Disable checking for updates")
    var disableUpdateCheck: Bool?

    @Flag(inversion: .prefixedNo, help: "Exit with non-zero status if any unused code is found")
    var strict: Bool?

    @Option(help: "Pass additional arguments to xcodebuild for the build phase")
    var xcargs: String?

    @Option(help: "Path to index store to use. Automatically defaults to the correct store for your project")
    var indexStorePath: String?

    @Flag(inversion: .prefixedNo, help: "Skip the project build step")
    var skipBuild: Bool?

    public init() {}

    public func run() throws {
        let scanBehavior = ScanBehavior.make()

        try scanBehavior.setup(config).get()

        let configuration = inject(Configuration.self)

        if let disableUpdateCheck = disableUpdateCheck {
            configuration.updateCheck = !disableUpdateCheck
        }

        if let retainPublic = retainPublic {
            configuration.retainPublic = retainPublic
        }

        if let retainObjcAnnotated = retainObjcAnnotated {
            configuration.retainObjcAnnotated = retainObjcAnnotated
        }

        if let retainUnusedProtocolFuncParams = retainUnusedProtocolFuncParams {
            configuration.retainUnusedProtocolFuncParams = retainUnusedProtocolFuncParams
        }

        if let verbose = verbose {
            configuration.verbose = verbose
        }

        if let quiet = quiet {
            configuration.quiet = quiet
        }

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

        if let strict = strict {
            configuration.strict = strict
        }

        if xcargs != nil {
            configuration.xcargs = xcargs
        }

        if let indexStorePath = indexStorePath {
            configuration.indexStorePath = indexStorePath
        }

        if let skipBuild = skipBuild {
            configuration.skipBuild = skipBuild
        }

        if let formatName = format {
            configuration.outputFormat = try OutputFormat.make(named: formatName)
        }

        configuration.guidedSetup = setup

        try scanBehavior.main { project in
            try Scan.make().perform(project: project)
        }.get()
    }

    fileprivate static func split(by delimiter: Character) -> (String?) -> [String] {
        return { options in options?.split(separator: delimiter).map(String.init) ?? [] }
    }
}
