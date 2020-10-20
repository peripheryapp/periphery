import Foundation
import ArgumentParser
import PathKit

public struct ScanCommand: ParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for unused code using all available techniques"
    )

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    var config: String?

    @Option(help: "Path to your project's .xcworkspace")
    var workspace: String?

    @Option(help: "Path to your project's .xcodeproj - supply this option if your project doesn't have an .xcworkspace")
    var project: String?

    @Option(help: "Comma separatered list of schemes that must be built in order to produce the targets passed to the --targets option", transform: split(by: ","))
    var schemes: [String] = []

    @Option(help: "Comma separatered list of schemes that must be built in order to produce the targets passed to the --targets option", transform: split(by: ","))
    var targets: [String] = []

    @Flag(inversion: .prefixedNo, help: "Retain all public declarations - you'll likely want to enable this if you're scanning a framework")
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

    @Option(help: "Save the build log so that it may be reused in subsequent scans to skip the build phase. The key passed to this option may then be used as the value for the '--use-build-log <key>' option in subsequent scans. Note that you should not reuse a build log generated by a different version of Xcode, the behavior of Periphery is undefined if you do so")
    var saveBuildLog: String?

    @Option(help: "Use the build log identified by the given key saved using '--save-build-log'. Or, use the build log at the given path (the log file must have a .log extension)")
    var useBuildLog: String?

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

    @Flag(inversion: .prefixedNo, help: "Enable new indexing system using IndexStore")
    var useIndexStore: Bool?

    @Option(help: "Path to index that should be loaded. e.g. DerivedData/PROJECT/Index/DataStore")
    var indexStorePath: String?

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

        if saveBuildLog != nil {
            configuration.saveBuildLog = saveBuildLog
        }

        if useBuildLog != nil {
            configuration.useBuildLog = useBuildLog
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

        if let useIndexStore = useIndexStore {
            configuration.useIndexStore = useIndexStore
        }

        if let indexStorePath = indexStorePath {
            configuration.indexStorePath = indexStorePath
        }

        if let formatName = format {
            configuration.outputFormat = try OutputFormat.make(named: formatName)
        }

        if configuration.workspace == nil &&
            configuration.project == nil &&
            configuration.schemes.isEmpty &&
            configuration.targets.isEmpty {
            configuration.guidedSetup = true
        }

        try scanBehavior.main { try Scan.make().perform() }.get()
    }

    fileprivate static func split(by delimiter: Character) -> (String?) -> [String] {
        return { options in options?.split(separator: delimiter).map(String.init) ?? [] }
    }
}
