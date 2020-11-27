import Foundation
import Shared
import PeripheryKit

final class JsonFormatter: OutputFormatter {
    public static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required public init(logger: Logger) {
        self.logger = logger
    }

    public func perform(_ declarations: [Declaration]) throws {
        var jsonObject: [Any] = []

        for decl in declarations {
            let object: [AnyHashable: Any] = [
                "kind": decl.kind.rawValue,
                "name": decl.name ?? "",
                "modifiers": Array(decl.modifiers),
                "attributes": Array(decl.attributes),
                "accessibility": decl.accessibility.value.rawValue,
                "ids": Array(decl.usrs),
                "hints": [describe(decl.analyzerHint) ?? ""],
                "location": decl.location.description
            ]
            jsonObject.append(object)

            switch decl.analyzerHint {
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
