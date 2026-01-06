import Configuration
import Foundation
import Logger
import SourceGraph
import SystemPackage

final class CsvFormatter: OutputFormatter {
    let configuration: Configuration
    let logger: Logger
    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration, logger: Logger) {
        self.logger = logger
        self.configuration = configuration
    }

    func format(_ results: [ScanResult], colored _: Bool) -> String? {
        var lines = ["Kind,Name,Modifiers,Attributes,Accessibility,IDs,Location,Hints"]

        for result in results {
            let line = format(
                kind: declarationKind(from: result.declaration),
                name: result.declaration.name,
                modifiers: result.declaration.modifiers,
                attributes: result.declaration.attributes.mapSet(\.description),
                accessibility: result.declaration.accessibility.value.rawValue,
                usrs: result.declaration.usrs,
                location: declarationLocation(from: result.declaration),
                hint: describe(result.annotation)
            )
            lines.append(line)

            switch result.annotation {
            case let .redundantProtocol(references, inherited):
                for ref in references {
                    let line = format(
                        kind: ref.kind.rawValue,
                        name: ref.name,
                        modifiers: [],
                        attributes: [],
                        accessibility: nil,
                        usrs: [ref.usr],
                        location: ref.location,
                        hint: redundantConformanceHint(with: inherited)
                    )
                    lines.append(line)
                }
            default:
                break
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private func format(
        kind: String,
        name: String?,
        modifiers: Set<String>,
        attributes: Set<String>,
        accessibility: String?,
        usrs: Set<String>,
        location: Location,
        hint: String?
    ) -> String {
        let joinedModifiers = attributes.sorted().joined(separator: "|")
        let joinedAttributes = modifiers.sorted().joined(separator: "|")
        let joinedUsrs = usrs.sorted().joined(separator: "|")
        let path = locationDescription(location)
        return "\(kind),\(name ?? ""),\(joinedModifiers),\(joinedAttributes),\(accessibility ?? ""),\(joinedUsrs),\(path),\(hint ?? "")"
    }
}
