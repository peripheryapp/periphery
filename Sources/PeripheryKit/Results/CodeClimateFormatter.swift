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
            let location = declarationLocation(from: result.declaration)

            let lines: [AnyHashable: Any] = [
                "begin": location.line,
            ]

            let locationDict: [AnyHashable: Any] = [
                "path": outputPath(location).url.relativePath,
                "lines": lines,
            ]

            let description = describe(result, colored: colored)
                .map(\.1)
                .joined(separator: ", ")
            let fingerprint = result.declaration.usrs.sorted().joined(separator: ".")

            let object: [AnyHashable: Any] = [
                "description": description,
                "fingerprint": fingerprint,
                "severity": "major",
                "location": locationDict,
            ]

            jsonObject.append(object)
        }

        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
        return String(bytes: data, encoding: .utf8)
    }
}
