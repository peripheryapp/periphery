import Foundation
import Shared
import PeripheryKit

final class XcodeFormatter: OutputFormatter {
    func format(_ results: [ScanResult]) throws -> String {
        guard results.count > 0 else {
            return colorize("* ", .boldGreen) + colorize("No unused code detected.", .bold)
        }

        return results.flatMap { result in
            describe(result, colored: true).map { (location, description) in
                prefix(for: location) + description
            }
        }
        .joined(separator: "\n")
    }

    // MARK: - Private

    private func prefix(for location: SourceLocation) -> String {
        let absPath = location.file.path.lexicallyNormalized()
        let path = absPath.removingLastComponent().string
        let file = colorize(absPath.lastComponent?.stem ?? "", .bold)
        let ext = absPath.extension ?? "swift"
        let lineNum = colorize(String(location.line), .bold)
        let column = location.column
        let warning = colorize("warning:", .boldYellow)

        return "\(path)/\(file).\(ext):\(lineNum):\(column): \(warning) "
    }
}
