import Foundation
import Shared
import PeripheryKit

final class JsonFormatter: OutputFormatter {
    static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required init(logger: Logger) {
        self.logger = logger
    }

    func perform(_ results: [ScanResult]) throws {
        var jsonObject: [Any] = []

        for result in results {
            let object: [AnyHashable: Any] = [
                "kind": result.declaration.kind.rawValue,
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
                        "modifiers": [],
                        "attributes": [],
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

        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        let json = String(data: data, encoding: .utf8)
        logger.info(json ?? "", canQuiet: false)
    }
}
