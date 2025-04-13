import Configuration
import Foundation
import SystemPackage

final class CodeClimateFormatter: OutputFormatter {
    let configuration: Configuration
    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func format(_ results: [ScanResult], colored: Bool) throws -> String? {
        var jsonObject: [Any] = []

        for result in results {
            let lines: [AnyHashable: Any] = [
                "begin": result.declaration.location.line,
            ]

            let location: [AnyHashable: Any] = [
                "path": outputPath(result.declaration.location).url.relativePath,
                "lines": lines,
            ]

            let description = describe(result, colored: colored)
                .map(\.1)
                .joined(separator: ", ")

            let fingerprint: String = if result.declaration.kind == .varParameter,
                                         let parentFingerprint = result.declaration.parent?.usrs.joined(separator: "."),
                                         let argumentName = result.declaration.name
            {
                // As function parameters do not have a mangled name that can be used for the fingerprint
                // we take the mangled name of the function and append the position
                "\(parentFingerprint)-\(argumentName)"
            } else {
                result.declaration.usrs.joined(separator: ".")
            }

            let object: [AnyHashable: Any] = [
                "description": description,
                "fingerprint": fingerprint,
                "severity": "major",
                "location": location,
            ]

            jsonObject.append(object)
        }

        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
        return String(bytes: data, encoding: .utf8)
    }
}
