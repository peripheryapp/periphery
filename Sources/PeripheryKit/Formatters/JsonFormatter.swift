import Foundation
import Shared

final class JsonFormatter: OutputFormatter {
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
                "location": result.declaration.location.description
            ]
            jsonObject.append(object)

            switch result.annotation {
            case let .redundantProtocol(references: references):
                for ref in references {
                    let object: [AnyHashable: Any] = [
                        "kind": ref.kind.rawValue,
                        "name": ref.name ?? "",
                        "modifiers": Array<String>(),
                        "attributes": Array<String>(),
                        "accessibility": "",
                        "ids": [ref.usr],
                        "hints": [redundantConformanceHint],
                        "location": ref.location.description
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
