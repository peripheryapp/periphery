import Foundation

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
            logger.info(colorize("➜  ", .boldGreen) + colorize("No unused code detected.", .bold))
            return
        }

        declarations.forEach {
            var line = prefix(for: $0.location)

            if var name = $0.name {
                if let kind = $0.kind.displayName, let first_ = kind.first {
                    let first = String(first_)
                    line += "\(first.uppercased())\(kind.dropFirst()) "
                }

                name = colorize(name, .lightBlue)
                line += "'\(name)' is unused"
            } else {
                line += "unused"
            }

            logger.info(line, canQuiet: false)
        }
    }

    // MARK: - Private

    private func prefix(for location: SourceLocation) -> String {
        let absPath = location.file.absolute()
        let path = absPath.components.dropLast().joined(separator: "/").dropFirst()
        let file = colorize(absPath.lastComponentWithoutExtension, .bold)
        let ext = absPath.extension ?? "swift"
        let lineNum = colorize(String(location.line ?? 0), .bold)
        let column = location.column ?? 0
        let warning = colorize("warning:", .boldYellow)

        return "\(path)/\(file).\(ext):\(lineNum):\(column): \(warning) "
    }
}
