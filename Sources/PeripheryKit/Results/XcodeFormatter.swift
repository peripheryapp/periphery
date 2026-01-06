import Configuration
import Foundation
import Logger
import SourceGraph
import SystemPackage

final class XcodeFormatter: OutputFormatter {
    let configuration: Configuration
    let logger: Logger
    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration, logger: Logger) {
        self.logger = logger
        self.configuration = configuration
    }

    func format(_ results: [ScanResult], colored: Bool) throws -> String? {
        guard !results.isEmpty else {
            return colorize("* ", .boldGreen, colored: colored) + colorize("No unused code detected.", .bold, colored: colored)
        }

        return results.flatMap { result in
            describe(result, colored: colored).map { location, description in
                prefix(for: location, colored: colored) + description
            }
        }
        .joined(separator: "\n")
    }

    // MARK: - Private

    private func prefix(for location: Location, colored: Bool) -> String {
        let path = outputPath(location)
        var dir = path.removingLastComponent().string

        if !dir.isEmpty {
            dir += "/"
        }

        let file = colorize(path.lastComponent?.stem ?? "", .bold, colored: colored)
        let ext = path.extension ?? "swift"
        let lineNum = colorize(String(location.line), .bold, colored: colored)
        let column = location.column
        let warning = colorize("warning:", .boldYellow, colored: colored)

        return "\(dir)\(file).\(ext):\(lineNum):\(column): \(warning) "
    }

    private func colorize(_ text: String, _ color: ANSIColor, colored: Bool) -> String {
        guard colored else { return text }

        return logger.colorize(text, color)
    }
}
