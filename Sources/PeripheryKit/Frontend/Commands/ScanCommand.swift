import Foundation
import Commandant
import Result

public struct ScanCommand: CommandProtocol {
    public let verb = "scan"
    public let function = "Scan for unused code using all available techniques"

    public init() {}

    public func run(_ options: ScanOptions) -> Result<(), PeripheryKitError> {
        let scanBehavior = ScanBehavior.make()

        if case let .failure(error) = scanBehavior.setup(options.config) {
            return .failure(error)
        }

        let configuration = inject(Configuration.self)

        if options.disableUpdateCheck.explicit {
            configuration.updateCheck = !options.disableUpdateCheck.value
        }

        if options.diagnose.explicit {
            configuration.diagnosisConsole = options.diagnose.value
        }

        if options.retainPublic.explicit {
            configuration.retainPublic = options.retainPublic.value
        }

        if options.retainObjcAnnotated.explicit {
            configuration.retainObjcAnnotated = options.retainObjcAnnotated.value
        }

        if options.retainUnusedProtocolFuncParams.explicit {
            configuration.retainUnusedProtocolFuncParams = options.retainUnusedProtocolFuncParams.value
        }

        if options.aggressive.explicit {
            configuration.aggressive = options.aggressive.value
        }

        if options.verbose.explicit {
            configuration.verbose = options.verbose.value
        }

        if options.quiet.explicit {
            configuration.quiet = options.quiet.value
        }

        if options.workspace != nil {
            configuration.workspace = options.workspace
        }

        if options.project != nil {
            configuration.project = options.project
        }

        if !options.indexExclude.isEmpty {
            configuration.indexExclude = options.indexExclude
        }

        if !options.reportExclude.isEmpty {
            configuration.reportExclude = options.reportExclude
        }

        if options.saveBuildLog != nil {
            configuration.saveBuildLog = options.saveBuildLog
        }

        if options.useBuildLog != nil {
            configuration.useBuildLog = options.useBuildLog
        }

        if !options.targets.isEmpty {
            configuration.targets = options.targets
        }

        if !options.schemes.isEmpty {
            configuration.schemes = options.schemes
        }

        do {
            if let formatName = options.format {
                configuration.outputFormat = try OutputFormat.make(named: formatName)
            }
        } catch let error as PeripheryKitError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        if configuration.workspace == nil &&
            configuration.project == nil &&
            configuration.schemes.isEmpty &&
            configuration.targets.isEmpty {
            configuration.guidedSetup = true
        }

        return scanBehavior.main { try Scan.make().perform() }
    }
}

public struct ScanOptions: OptionsProtocol {
    let config: String?
    let workspace: String?
    let project: String?
    let schemes: [String]
    let targets: [String]
    let retainPublic: BoolValue
    let retainObjcAnnotated: BoolValue
    let retainUnusedProtocolFuncParams: BoolValue
    let aggressive: BoolValue
    let format: String?
    let indexExclude: [String]
    let reportExclude: [String]
    let diagnose: BoolValue
    let verbose: BoolValue
    let quiet: BoolValue
    let disableUpdateCheck: BoolValue
    let saveBuildLog: String?
    let useBuildLog: String?
    let strict: BoolValue

    public static func create(_ config: String?) -> (_ workspace: String?) -> (_ project: String?) -> (_ schemes: String) -> (_ targets: String) -> (_ retainPublic: BoolValue) -> (_ retainObjcAnnotated: BoolValue) -> (_ retainUnusedProtocolFuncParams: BoolValue) -> (_ aggressive: BoolValue) -> (_ format: String?) -> (_ indexExclude: String?) -> (_ reportExclude: String?) -> (_ saveBuildLog: String?) -> (_ useBuildLog: String?) -> (_ diagnose: BoolValue) -> (_ verbose: BoolValue) -> (_ quiet: BoolValue) -> (_ disableUpdateCheck: BoolValue) -> (_ strict: BoolValue) -> ScanOptions {
        return { workspace in { project in { schemes in { targets in { retainPublic in { retainObjcAnnotated in { retainUnusedProtocolFuncParams in { aggressive in { format in { indexExclude in { reportExclude in { saveBuildLog in { useBuildLog in { diagnose in { verbose in { quiet in { disableUpdateCheck in { strict in
            return self.init(config: config,
                             workspace: workspace,
                             project: project,
                             schemes: parse(schemes, ","),
                             targets: parse(targets, ","),
                             retainPublic: retainPublic,
                             retainObjcAnnotated: retainObjcAnnotated,
                             retainUnusedProtocolFuncParams: retainUnusedProtocolFuncParams,
                             aggressive: aggressive,
                             format: format,
                             indexExclude: parse(indexExclude, "|"),
                             reportExclude: parse(reportExclude, "|"),
                             diagnose: diagnose,
                             verbose: verbose,
                             quiet: quiet,
                             disableUpdateCheck: disableUpdateCheck,
                             saveBuildLog: saveBuildLog,
                             useBuildLog: useBuildLog,
                             strict: strict)
            }}}}}}}}}}}}}}}}}}
    }

    public static func evaluate(_ mode: CommandMode) -> Result<ScanOptions, CommandantError<PeripheryKitError>> {
        let outputFormatters = OutputFormat.allCases.map { $0.rawValue }.joined(separator: ", ")
        let config = Configuration()

        return create
            <*> mode <| Option(key: "config",
                               defaultValue: nil,
                               usage: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")

            <*> mode <| Option(key: "workspace",
                               defaultValue: nil,
                               usage: "Path to your project's .xcworkspace")

            <*> mode <| Option(key: "project",
                               defaultValue: nil,
                               usage: "Path to your project's .xcodeproj - supply this option if your project doesn't have an .xcworkspace")

            <*> mode <| Option(key: "schemes",
                               defaultValue: "",
                               usage: "Comma separatered list of schemes that must be built in order to produce the targets passed to the --targets option")

            <*> mode <| Option(key: "targets",
                               defaultValue: "",
                               usage: "Comma separatered list of target names to scan")

            <*> mode <| Option(key: "retain-public",
                               defaultValue: BoolValue(config.retainPublic),
                               usage: "Retain all public declarations - you'll likely want to enable this if you're scanning a framework")

            <*> mode <| Option(key: "retain-objc-annotated",
                               defaultValue: BoolValue(config.retainObjcAnnotated),
                               usage: "Don't retain declarations that are exposed to Objective-C by inheriting NSObject, or explicitly with the @objc and @objcMembers annotations")

            <*> mode <| Option(key: "retain-unused-protocol-func-params",
                               defaultValue: BoolValue(config.retainUnusedProtocolFuncParams),
                               usage: "Retain unused protocol function parameters, even if the parameter is unused in all conforming functions")

            <*> mode <| Option(key: "aggressive",
                               defaultValue: BoolValue(config.aggressive),
                               usage: "Enable heuristics that may produce false negatives")

            <*> mode <| Option(key: "format",
                               defaultValue: nil,
                               usage: "Output format, available formatters are: \(outputFormatters)")

            <*> mode <| Option(key: "index-exclude",
                               defaultValue: nil,
                               usage: "Path glob of source files which should be excluded from indexing. Declarations and references within these files will not be considered during analysis. Multiple globs may be delimited by a pipe")

            <*> mode <| Option(key: "report-exclude",
                               defaultValue: nil,
                               usage: "Path glob of source files which should be excluded from the results. Note that this option is purely cosmetic, these files will still be indexed. Multiple globs may be delimited by a pipe")

            <*> mode <| Option(key: "save-build-log",
                               defaultValue: nil,
                               usage: "Save the build log so that it may be reused in subsequent scans to skip the build phase. The key passed to this option may then be used as the value for the '--use-build-log <key>' option in subsequent scans. Note that you should not reuse a build log generated by a different version of Xcode, the behavior of Periphery is undefined if you do so")

            <*> mode <| Option(key: "use-build-log",
                               defaultValue: nil,
                               usage: "Use the build log identified by the given key saved using '--save-build-log'. Or, use the build log at the given path (the log file must have a .log extension)")

            <*> mode <| Option(key: "diagnose",
                               defaultValue: BoolValue(config.diagnosisConsole),
                               usage: "Start an interactive diagnosis console after analysis completes")

            <*> mode <| Option(key: "verbose",
                               defaultValue: BoolValue(config.verbose),
                               usage: "Enable verbose logging")

            <*> mode <| Option(key: "quiet",
                               defaultValue: BoolValue(config.quiet),
                               usage: "Only output results")

            <*> mode <| Option(key: "disable-update-check",
                               defaultValue: BoolValue(!config.updateCheck),
                               usage: "Disable checking for updates")

            <*> mode <| Option(key: "fail-on-warnings",
                               defaultValue: BoolValue(config.strict),
                               usage: "Make sure command fails if any warnings are encountered")
    }

    private static func parse(_ option: String?, _ delimiter: Character) -> [String] {
        return option?.split(separator: delimiter).map(String.init) ?? []
    }
}
