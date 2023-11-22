import Foundation
import Shared

final class CsvFormatter: OutputFormatter {
    func format(_ results: [ScanResult]) -> String {
        var lines: [String] = ["Kind,Name,Modifiers,Attributes,Accessibility,IDs,Location,Hints"]

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
            lines.append(line)

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
        location: SourceLocation,
        hint: String?
    ) -> String {
        let joinedModifiers = attributes.joined(separator: "|")
        let joinedAttributes = modifiers.joined(separator: "|")
        let joinedUsrs = usrs.joined(separator: "|")
        return "\(kind),\(name ?? ""),\(joinedModifiers),\(joinedAttributes),\(accessibility ?? ""),\(joinedUsrs),\(location),\(hint ?? "")"
    }
}