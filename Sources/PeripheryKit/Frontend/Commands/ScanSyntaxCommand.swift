import Foundation
import ArgumentParser

public struct ScanSyntaxCommand: ParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "scan-syntax",
        abstract: "Scan for unused code using fast syntax only analysis techniques (currently only unused function parameter analysis)"
    )

    @Option(help: "Path to configuration file. By default Periphery will look for .periphery.yml in the current directory")
    var config: String?

    @Option(help: "Output format, available formatters are: \(OutputFormat.allCases.map { $0.rawValue }.joined(separator: ", "))")
    var format: String?

    @Option(help: "Path glob of source files which should not be scanned. Multiple globs may be delimited by a pipe", transform: split(by: "|"))
    var exclude: [String] = []

    @Flag(inversion: .prefixedNo, help: "Enable verbose logging")
    var verbose: Bool?

    @Flag(inversion: .prefixedNo, help: "Only output results")
    var quiet: Bool?

    @Flag(inversion: .prefixedNo, help: "Exit with non-zero status if any unused code is found")
    var strict: Bool?

    @Argument(help: "Path glob to scan")
    var path: String

    public init() {}

    public func run() throws {
        let scanBehavior = ScanBehavior.make()

        try scanBehavior.setup(config).get()

        let configuration = inject(Configuration.self)

        if let verbose = verbose {
            configuration.verbose = verbose
        }

        if let quiet = quiet {
            configuration.quiet = quiet
        }

        if !exclude.isEmpty {
            // TODO: This smells, but need a nice to way to isolate options per command, and also share some.
            configuration.reportExclude = exclude
        }

        if let strict = strict {
            configuration.strict = strict
        }

        if let formatName = format {
            configuration.outputFormat = try OutputFormat.make(named: formatName)
        }

        try scanBehavior.main { try ScanSyntax.make().perform(path) }.get()
    }


    fileprivate static func split(by delimiter: Character) -> (String?) -> [String] {
        return { options in options?.split(separator: delimiter).map(String.init) ?? [] }
    }
}
