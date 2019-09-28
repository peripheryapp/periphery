import Foundation

public final class CsvFormatter: OutputFormatter {
    public static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required public init(logger: Logger) {
        self.logger = logger
    }

    public func perform(_ declarations: [Declaration]) {
        logger.info("Kind,Name,Attributes,Accessibility,ID,Location,Hints", canQuiet: false)

        declarations.forEach {
            let attributes = $0.attributes.joined(separator: "|")
            let hints = $0.analyzerHints.map { String(describing: $0) }.joined(separator: "|")

            logger.info("\($0.kind.shortName),\($0.name ?? ""),\(attributes),\($0.accessibility.shortName),\($0.usr),\($0.location),\(hints)", canQuiet: false)
        }
    }
}
