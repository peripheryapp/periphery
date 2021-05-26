import Foundation
import Shared
import PeripheryKit

final class CsvFormatter: OutputFormatter {
    static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required init(logger: Logger) {
        self.logger = logger
    }

    func perform(_ results: [ScanResult]) {
        logger.info("Kind,Name,Modifiers,Attributes,Accessibility,IDs,Location,Hints", canQuiet: false)

        for result in results {
            let line = format(
                kind: result.declaration.kind.rawValue,
                name: result.declaration.name,
                modifiers: result.declaration.modifiers,
                attributes: result.declaration.attributes,
                accessibility: result.declaration.accessibility.value.rawValue,
                usrs: result.declaration.usrs,
                location: result.declaration.location,
                hint: describe(result.annotation)
            )
            logger.info(line, canQuiet: false)

            switch result.annotation {
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
