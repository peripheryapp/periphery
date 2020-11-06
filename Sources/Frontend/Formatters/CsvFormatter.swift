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
        logger.info("Kind,Name,Modifiers,Attributes,Accessibility,ID,Location,Hints", canQuiet: false)

        declarations.forEach {
            let modifiers = $0.modifiers.joined(separator: "|")
            let attributes = $0.attributes.joined(separator: "|")
            logger.info("\($0.kind.rawValue),\($0.name ?? ""),\(modifiers),\(attributes),\($0.accessibility.value.rawValue),\($0.usr),\($0.location)", canQuiet: false)
        }
    }
}
