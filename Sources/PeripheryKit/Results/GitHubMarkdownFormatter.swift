import Configuration
import SystemPackage

final class GitHubMarkdownFormatter: OutputFormatter {
    let configuration: Configuration
    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func format(_ results: [ScanResult], colored _: Bool) throws -> String? {
        guard !results.isEmpty else {
            return "No unused code detected."
        }

        let visibleResults = results.prefix(10).flatMap { format($0) }
        let expandableResults = results.dropFirst(10).flatMap { format($0) }
        let title = results.count == 1 ? "Result" : "Results"

        var markdown = """
        | \(results.count) \(title) |
        | :- |
        \(visibleResults.joined(separator: "\n"))
        """

        if !expandableResults.isEmpty {
            let expandableTitle = expandableResults.count == 1 ? "result" : "results"
            markdown += """

            <details>
              <summary>Show remaining \(expandableResults.count) \(expandableTitle)</summary>
              <br>

              | |
              | :- |
              \(expandableResults.joined(separator: "\n"))

            </details>
            """
        }

        return markdown
    }

    // MARK: - Private

    private func format(_ result: ScanResult) -> [String] {
        describe(result, colored: false).map { location, description in
            "| **\(description)**<br>\(locationDescription(location)) |"
        }
    }
}
