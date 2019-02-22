import Foundation
import Commandant
import Result

public struct ScanSyntaxCommand: CommandProtocol {
    public let verb = "scan-syntax"
    public let function = "Scan for unused code using fast syntax only analysis techniques (currently only unused function parameter analysis)"

    public init() {}

    public func run(_ options: ScanSyntaxOptions) -> Result<(), PeripheryKitError> {
        let scanBehavior = ScanBehavior.make()

        if case let .failure(error) =
            scanBehavior.setup(options.config) {
            return .failure(error)
        }

        let configuration = inject(Configuration.self)

        if options.verbose.explicit {
            configuration.verbose = options.verbose.value
        }

        if options.quiet.explicit {
            configuration.quiet = options.quiet.value
        }

        if !options.exclude.isEmpty {
            // TODO: This smells, but need a nice to way to isolate options per command, and also share some.
            configuration.reportExclude = options.exclude
        }

        if options.strict.explicit {
            configuration.strict = options.strict.value
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

        return scanBehavior.main { try ScanSyntax.make().perform(options.path) }
    }
}

public struct ScanSyntaxOptions: OptionsProtocol {
    let config: String?
    let format: String?
    let exclude: [String]
    let verbose: BoolValue
    let quiet: BoolValue
    let strict: BoolValue
    let path: String

    public static func create(_ config: String?) -> (_ format: String?) -> (_ exclude: String?) -> (_ verbose: BoolValue) -> (_ quiet: BoolValue) -> (_ strict: BoolValue) -> (_ path: String) -> ScanSyntaxOptions {
        return { format in { exclude in { verbose in { quiet in { strict in { path in
            return self.init(config: config,
                             format: format,
                             exclude: parse(exclude, "|"),
                             verbose: verbose,
                             quiet: quiet,
                             strict: strict,
                             path: path)
            }}}}}}
    }

    public static func evaluate(_ m: CommandMode) -> Result<ScanSyntaxOptions, CommandantError<PeripheryKitError>> {
        let outputFormatters = OutputFormat.allCases.map { $0.rawValue }.joined(separator: ", ")
        let config = Configuration()

        return create
            <*> m <| Option(key: "config",
                            defaultValue: nil,
                            usage: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")

            <*> m <| Option(key: "format",
                            defaultValue: nil,
                            usage: "Output format, available formatters are: \(outputFormatters)")

            <*> m <| Option(key: "exclude",
                            defaultValue: nil,
                            usage: "Path glob of source files which should not be scanned. Multiple globs may be delimited by a pipe")

            <*> m <| Option(key: "verbose",
                            defaultValue: BoolValue(config.verbose),
                            usage: "Enable verbose logging")

            <*> m <| Option(key: "quiet",
                            defaultValue: BoolValue(config.quiet),
                            usage: "Only output results")

            <*> m <| Option(key: "strict",
                            defaultValue: BoolValue(config.strict),
                            usage: "Exit with non-zero status if any unused code is found")

            <*> m <| Argument(usage: "Path glob to scan")
    }

    private static func parse(_ option: String?, _ delimiter: Character) -> [String] {
        return option?.split(separator: delimiter).map(String.init) ?? []
    }
}
