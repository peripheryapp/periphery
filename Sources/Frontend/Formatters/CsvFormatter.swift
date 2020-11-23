import Foundation
import Shared
import PeripheryKit

public final class CsvFormatter: OutputFormatter {
    public static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required public init(logger: Logger) {
        self.logger = logger
    }

    public func perform(_ declarations: [Declaration]) {
        logger.info("Kind,Name,Modifiers,Attributes,Accessibility,IDs,Location,Hints", canQuiet: false)

        declarations.forEach {
            let modifiers = $0.modifiers.joined(separator: "|")
            let attributes = $0.attributes.joined(separator: "|")
            let hints = $0.analyzerHints.map { String(describing: $0) }.joined(separator: "|")
            let usrs = $0.usrs.joined(separator: "|")

            logger.info("\($0.kind.rawValue),\($0.name ?? ""),\(modifiers),\(attributes),\($0.accessibility.value.rawValue),\(usrs),\($0.location),\(hints)", canQuiet: false)
        }
    }
}
