import Configuration
import Foundation
import Shared
import SourceGraph
import SystemPackage

final class GitHubActionsFormatter: OutputFormatter {
    let configuration: Configuration
    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func format(_ results: [ScanResult]) throws -> String {
        guard !results.isEmpty else { return "" }
        guard configuration.relativeResults else { throw PeripheryError.usageError("`periphery scan` must be ran with `--relative-results` when using the GitHub Actions formatter") }

        return results.flatMap { result in
            describe(result, colored: false).map { location, description in
                prefix(for: location, result: result) + description
            }
        }
        .joined(separator: "\n")
    }

    // MARK: - Private

    private func prefix(for location: Location, result: ScanResult) -> String {
        let path = outputPath(location)
        let lineNum = String(location.line)
        let column = location.column
        let title = describe(result.annotation)

        return "::warning file=\(path),line=\(lineNum),col=\(column),title=\(title)::"
    }
}
