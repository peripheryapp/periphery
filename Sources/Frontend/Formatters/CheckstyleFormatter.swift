import Foundation
import PathKit
import Shared
import PeripheryKit

public final class CheckstyleFormatter: OutputFormatter {
    public static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required public init(logger: Logger) {
        self.logger = logger
    }

    public func perform(_ declarations: [Declaration]) {
        let results = declarations.flatMap { describeResults(for: $0, colored: false) }
        let xml = [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">",
            results
                .group(by: { ($0.0.file.string).escapedForXML() })
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
