import Configuration
import Foundation
import Logger
import SystemPackage

final class JsonFormatter: OutputFormatter {
    let configuration: Configuration
    let logger: Logger
    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration, logger: Logger) {
        self.logger = logger
        self.configuration = configuration
    }

    func format(_ results: [ScanResult], colored _: Bool) throws -> String? {
        var jsonObject: [Any] = []

        for result in results {
            let location = declarationLocation(from: result.declaration)
            let object: [AnyHashable: Any] = [
                "kind": declarationKind(from: result.declaration),
                "modules": location.file.modules.sorted(),
                "name": result.declaration.name ?? "",
                "modifiers": result.declaration.modifiers.sorted(),
                "attributes": result.declaration.attributes.sorted(),
                "accessibility": result.declaration.accessibility.value.rawValue,
                "ids": result.declaration.usrs.sorted(),
                "hints": [describe(result.annotation)],
                "location": locationDescription(location),
            ]
            jsonObject.append(object)

            switch result.annotation {
            case let .redundantProtocol(references, inherited):
                for ref in references {
                    let object: [AnyHashable: Any] = [
                        "kind": ref.kind.rawValue,
                        "name": ref.name ?? "",
                        "modifiers": [String](),
                        "attributes": [String](),
                        "accessibility": "",
                        "ids": [ref.usr],
                        "hints": [redundantConformanceHint(with: inherited)],
                        "location": locationDescription(ref.location),
                    ]
                    jsonObject.append(object)
                }
            default:
                break
            }
        }

        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
        return String(bytes: data, encoding: .utf8)
    }
}
