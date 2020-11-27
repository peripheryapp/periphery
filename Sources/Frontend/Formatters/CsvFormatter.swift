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

        for decl in declarations {
            let line = format(
                kind: decl.kind.rawValue,
                name: decl.name,
                modifiers: decl.modifiers,
                attributes: decl.attributes,
                accessibility: decl.accessibility.value.rawValue,
                usrs: decl.usrs,
                location: decl.location,
                hint: describe(decl.analyzerHint))
            logger.info(line, canQuiet: false)

            switch decl.analyzerHint {
            case let .redundantProtocol(references: references):
                for ref in references {
                    let line = format(
                        kind: ref.kind.rawValue,
                        name: ref.name,
                        modifiers: [],
                        attributes: [],
                        accessibility: nil,
                        usrs: [ref.usr],
                        location: ref.location,
                        hint: redundantConformanceHint)
                    logger.info(line, canQuiet: false)
                }
            default:
                break
            }
        }
    }

    // MARK: - Private

    private func format(
        kind: String,
        name: String?,
        modifiers: Set<String>,
        attributes: Set<String>,
        accessibility: String?,
        usrs: Set<String>,
        location: SourceLocation,
        hint: String?
    ) -> String {
        let joinedModifiers = attributes.joined(separator: "|")
        let joinedAttributes = modifiers.joined(separator: "|")
        let joinedUsrs = usrs.joined(separator: "|")
        return "\(kind),\(name ?? ""),\(joinedModifiers),\(joinedAttributes),\(accessibility ?? ""),\(joinedUsrs),\(location),\(hint ?? "")"
    }
}
