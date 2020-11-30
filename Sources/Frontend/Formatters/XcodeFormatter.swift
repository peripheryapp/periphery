import Foundation
import Shared
import PeripheryKit

public final class XcodeFormatter: OutputFormatter {
    public static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required public init(logger: Logger) {
        self.logger = logger
    }

    public func perform(_ declarations: [Declaration]) throws {
        guard declarations.count > 0 else {
            logger.info(colorize("* ", .boldGreen) + colorize("No unused code detected.", .bold))
            return
        }

        for decl in declarations {
            let results = describeResults(for: decl, colored: true)

            for (location, result) in results {
                let line = prefix(for: location) + result
                logger.info(line, canQuiet: false)
            }
        }
    }

    // MARK: - Private

    private func prefix(for location: SourceLocation) -> String {
        let absPath = location.file.absolute()
        let path = absPath.components.dropLast().joined(separator: "/").dropFirst()
        let file = colorize(absPath.lastComponentWithoutExtension, .bold)
        let ext = absPath.extension ?? "swift"
        let lineNum = colorize(String(location.line), .bold)
        let column = location.column
        let warning = colorize("warning:", .boldYellow)

        return "\(path)/\(file).\(ext):\(lineNum):\(column): \(warning) "
    }
}
