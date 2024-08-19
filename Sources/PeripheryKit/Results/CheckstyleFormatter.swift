import Foundation
import Shared
import SourceGraph
import SystemPackage

final class CheckstyleFormatter: OutputFormatter {
    let configuration: Configuration
    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func format(_ results: [ScanResult]) -> String {
        let parts = results.flatMap { describe($0, colored: false) }
        return [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">",
            parts
                .group(by: { outputPath($0.0).string.escapedForXML() })
                .sorted(by: { $0.key < $1.key })
                .map(generateForFile).joined(),
            "\n</checkstyle>",
        ].joined()
    }

    // MARK: - Private

    private func generateForFile(_ file: String, results: [(Location, String)]) -> String {
        [
            "\n\t<file name=\"", file, "\">\n",
            results.map(generateForResult).joined(),
            "\t</file>",
        ].joined()
    }

    private func generateForResult(_ result: (Location, String)) -> String {
        let line = result.0.line
        let col = result.0.column

        return [
            "\t\t<error line=\"\(line)\" ",
            "column=\"\(col)\" ",
            "severity=\"warning\" ",
            "message=\"", result.1.escapedForXML(), "\"/>\n",
        ].joined()
    }
}
