import Foundation
import Shared
import SourceGraph
import SystemPackage

final class XcodeFormatter: OutputFormatter {
    let configuration: Configuration
    lazy var currentFilePath: FilePath = { .current }()

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func format(_ results: [ScanResult]) throws -> String {
        guard !results.isEmpty else {
            return colorize("* ", .boldGreen) + colorize("No unused code detected.", .bold)
        }

        return results.flatMap { result in
            describe(result, colored: true).map { location, description in
                prefix(for: location) + description
            }
        }
        .joined(separator: "\n")
    }

    // MARK: - Private

    private func prefix(for location: Location) -> String {
        let path = outputPath(location)
        let dir = path.removingLastComponent()
        let file = colorize(path.lastComponent?.stem ?? "", .bold)
        let ext = path.extension ?? "swift"
        let lineNum = colorize(String(location.line), .bold)
        let column = location.column
        let warning = colorize("warning:", .boldYellow)

        return "\(dir)/\(file).\(ext):\(lineNum):\(column): \(warning) "
    }
}
