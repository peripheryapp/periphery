import Foundation
import Shared
import PeripheryKit

final class XcodeFormatter: OutputFormatter {
    static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required init(logger: Logger) {
        self.logger = logger
    }

    func perform(_ results: [ScanResult]) throws {
        guard results.count > 0 else {
            logger.info(colorize("* ", .boldGreen) + colorize("No unused code detected.", .bold))
            return
        }

        for result in results {
            let descriptions = describe(result, colored: true)

            for (location, description) in descriptions {
                let line = prefix(for: location) + description
                logger.info(line, canQuiet: false)
            }
        }
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
