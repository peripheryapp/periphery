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

    @Flag(help: "Exit with non-zero status if any unused code is found")
    var strict: Bool = false

    @Flag(help: "Enable verbose logging")
    var verbose: Bool = false

    @Flag(help: "Only output results")
    var quiet: Bool = false

    @Argument(help: "Path glob to scan")
    var path: String

    public init() {}

    public func run() throws {
        let scanBehavior = ScanBehavior.make()

        try scanBehavior.setup(config).get()

        let configuration = inject(Configuration.self)

        if !exclude.isEmpty {
            // TODO: This smells, but need a nice to way to isolate options per command, and also share some.
            configuration.reportExclude = exclude
        }

        if let formatName = format {
            configuration.outputFormat = try OutputFormat.make(named: formatName)
        }

        if isExplicit("strict") {
            configuration.strict = strict
        }

        if isExplicit("verbose") {
            configuration.verbose = verbose
        }

        if isExplicit("quiet") {
            configuration.quiet = quiet
        }

        try scanBehavior.main { project in
            try ScanSyntax.make().perform(path)
        }.get()
    }

    private func isExplicit(_ arg: String) -> Bool {
        CommandLine.arguments.contains { $0.hasSuffix(arg) }
    }

    fileprivate static func split(by delimiter: Character) -> (String?) -> [String] {
        return { options in options?.split(separator: delimiter).map(String.init) ?? [] }
    }
}
