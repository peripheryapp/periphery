import Configuration
import Foundation
import Logger
import SystemPackage

final class SonarQubeFormatter: OutputFormatter {
    let configuration: Configuration

    let logger: Logger

    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration, logger: Logger) {
        self.logger = logger
        self.configuration = configuration
    }

    func format(_ results: [ScanResult], colored: Bool) throws -> String? {
        var ruleIds: Set<String> = []
        var rules: [Any] = []
        var issues: [Any] = []

        for result in results {
            let ruleId = describe(result.annotation)
            if !ruleIds.contains(ruleId) {
                ruleIds.insert(ruleId)
                rules.append([
                    "id": ruleId,
                    "name": result.annotation.name,
                    "description": result.annotation.description,
                    "engineId": "periphery",
                    "cleanCodeAttribute": "EFFICIENT",
                    "type": "CODE_SMELL",
                    "severity": configuration.sonarqubeRuleSeverity.rawValue
                ])
            }

            var descriptions = self.describe(result, colored: false)
            guard !descriptions.isEmpty else { continue }
            let primaryResult = descriptions.removeFirst()
            let location = primaryResult.0
            var issue: [String: Any] = [
                "ruleId": ruleId,
                "primaryLocation": [
                    "message": primaryResult.1,
                    "filePath": outputPath(location).string,
                    "textRange": [
                        "startLine": location.line,
                        "startColumn": max(0, location.column - 1)
                    ]
                ]
            ]
            if !descriptions.isEmpty {
                issue["secondaryLocations"] = descriptions.map({ location, message in
                    [
                        "message": message,
                        "filePath": outputPath(location).string,
                        "textRange": [
                            "startLine": location.line,
                            "startColumn": max(0, location.column - 1)
                        ]
                    ]
                })
            }
            issues.append(issue)
        }

        let report = [
            "rules": rules,
            "issues": issues
        ]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .withoutEscapingSlashes])
        return String(bytes: data, encoding: .utf8)
    }
}

private extension ScanResult.Annotation {
    var name: String {
        switch self {
        case .unused:
            "Unused Declaration"
        case .assignOnlyProperty:
            "Assign-only Property"
        case .redundantProtocol:
            "Redundant Protocol"
        case .redundantPublicAccessibility:
            "Redundant Public Accessibility"
        case .superfluousIgnoreCommand:
            "Superfluous Ignore Comment"
        }
    }

    var description: String {
        switch self {
        case .unused:
            "Unused Declaration"
        case .assignOnlyProperty:
            "Property is assigned but never used"
        case .redundantProtocol:
            "Protocol is never used as an existential type"
        case .redundantPublicAccessibility:
            "Public accessibility is redundant as declaration is not used outside its module"
        case .superfluousIgnoreCommand:
            "Ignore comment is unnecessary as declaration is referenced"
        }
    }
}
