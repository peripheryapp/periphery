import Foundation
import Shared
import PeripheryKit

final class CheckstyleFormatter: OutputFormatter {
    static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required init(logger: Logger) {
        self.logger = logger
    }

    func perform(_ results: [ScanResult]) {
        let parts = results.flatMap { describe($0, colored: false) }
        let xml = [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">",
            parts
                .group(by: { ($0.0.file.path.string).escapedForXML() })
                .sorted(by: { $0.key < $1.key })
                .map(generateForFile).joined(),
            "\n</checkstyle>"
        ].joined()
        logger.info(xml, canQuiet: false)
    }

    // MARK: - Private

    private func generateForFile(_ file: String, results: [(SourceLocation, String)]) -> String {
        return [
            "\n\t<file name=\"", file, "\">\n",
            results.map(generateForResult).joined(),
            "\t</file>"
        ].joined()
    }

    private func generateForResult(_ result: (SourceLocation, String)) -> String {
        let line = result.0.line
        let col = result.0.column

        return [
            "\t\t<error line=\"\(line)\" ",
            "column=\"\(col)\" ",
            "severity=\"warning\" ",
            "message=\"", result.1.escapedForXML(), "\"/>\n"
        ].joined()
    }
}
