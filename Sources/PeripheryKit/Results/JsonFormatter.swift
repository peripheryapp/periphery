import Foundation
import Shared
import SystemPackage

final class JsonFormatter: OutputFormatter {
    let configuration: Configuration
    lazy var currentFilePath: FilePath = { .current }()

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func format(_ results: [ScanResult]) throws -> String {
        var jsonObject: [Any] = []

        for result in results {
            let object: [AnyHashable: Any] = [
                "kind": result.declaration.kind.rawValue,
                "modules": Array(result.declaration.location.file.modules),
                "name": result.declaration.name ?? "",
                "modifiers": Array(result.declaration.modifiers),
                "attributes": Array(result.declaration.attributes),
                "accessibility": result.declaration.accessibility.value.rawValue,
                "ids": Array(result.declaration.usrs),
                "hints": [describe(result.annotation)],
                "location": locationDescription(result.declaration.location)
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
                        "location": locationDescription(ref.location)
                    ]
                    jsonObject.append(object)
                }
            default:
                break
            }
        }

        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
        let json = String(data: data, encoding: .utf8)
        return json ?? ""
    }
}
