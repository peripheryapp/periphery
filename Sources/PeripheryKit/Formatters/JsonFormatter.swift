import Foundation

class JsonFormatter: OutputFormatter {
    public static func make() -> Self {
        return self.init(logger: inject())
    }

    private let logger: Logger

    required public init(logger: Logger) {
        self.logger = logger
    }

    public func perform(_ declarations: [Declaration]) throws {
        var jsonObject: [Any] = []

        declarations.forEach {
            let object: [AnyHashable: Any] = [
                "kind": $0.kind.shortName,
                "name": $0.name ?? "",
                "attributes": $0.attributes.map { $0 },
                "accessibility": $0.accessibility.shortName,
                "id": $0.usr,
                "location": $0.location.description,
                "hints": $0.analyzerHints.map { String(describing: $0) }
            ]
            jsonObject.append(object)
        }

        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        let json = String(data: data, encoding: .utf8)
        logger.info(json ?? "", canQuiet: false)
    }
}
