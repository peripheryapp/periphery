import Configuration
import Foundation
import SystemPackage

final class GitLabCodeQualityFormatter: OutputFormatter {
    let configuration: Configuration
    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func format(_ results: [ScanResult], colored: Bool) throws -> String? {
        var jsonObject: [Any] = []

        for result in results {
            let violationFileLocation = declarationLocation(from: result.declaration)

            let description = describe(result, colored: colored)
                .map(\.1)
                .joined(separator: ", ")

            let checkName = describe(result.annotation)

            let fingerprint = result
                .declaration
                .usrs
                .sorted()
                .joined(separator: ".")

            let begin = violationFileLocation.line
            let lines: [AnyHashable: Any] = [
                "begin": begin,
            ]

            let path = outputPath(violationFileLocation)
                .url
                .relativePath

            let location: [AnyHashable: Any] = [
                "path": path,
                "lines": lines,
            ]

            let object: [AnyHashable: Any] = [
                "description": description,
                "check_name": checkName,
                "fingerprint": fingerprint,
                "location": location,
                "severity": "info",
            ]

            jsonObject.append(object)
        }

        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes])
        return String(bytes: data, encoding: .utf8)
    }
}
