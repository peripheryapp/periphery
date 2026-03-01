import Configuration
import Foundation
import Logger
import SystemPackage

final class SonarQubeFormatter: OutputFormatter {
    let configuration: Configuration
    lazy var ruleSeverity = configuration.sonarQubeRuleSeverity ?? .default

    let logger: Logger

    lazy var currentFilePath: FilePath = .current

    init(configuration: Configuration, logger: Logger) {
        self.logger = logger
        self.configuration = configuration
    }

    // MARK: - Encodable Types for JSON

    private struct SonarQubeReport: Encodable {
        let rules: Set<Rule>
        let issues: [Issue]
    }

    private struct Rule: Encodable, Hashable {
        let id: String
        let name: String
        let description: String
        let engineId: String
        let cleanCodeAttribute: String
        let type: String
        let severity: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    private struct Issue: Encodable {
        let ruleId: String
        let primaryLocation: Location
        let secondaryLocations: [Location]?
    }

    private struct Location: Encodable {
        let message: String
        let filePath: String
        let textRange: TextRange
    }

    private struct TextRange: Encodable {
        let startLine: Int
        let startColumn: Int

        init(startLine: Int, startColumn: Int) {
            self.startLine = startLine
            // Column index for SonarQube report is expected to be 0 based.
            self.startColumn = startColumn - 1
        }
    }

    func format(_ results: [ScanResult], colored: Bool) throws -> String? {
        var issues: [Issue] = []
        var rules: Set<Rule> = []

        for result in results {
            let ruleId = describe(result.annotation)

            rules.insert(
                .init(
                    id: ruleId,
                    name: result.annotation.name,
                    description: result.annotation.description,
                    engineId: "periphery",
                    cleanCodeAttribute: "EFFICIENT",
                    type: "CODE_SMELL",
                    severity: ruleSeverity.rawValue
                )
            )

            var descriptions = self.describe(result, colored: false)
            guard !descriptions.isEmpty else { continue }
            let primaryResult = descriptions.removeFirst()
            let location = primaryResult.0
            let issue = Issue(
                ruleId: ruleId,
                primaryLocation: .init(
                    message: primaryResult.1,
                    filePath: outputPath(location).string,
                    textRange: .init(
                        startLine: location.line,
                        startColumn: location.column)
                ),
                secondaryLocations: descriptions.isEmpty ? nil : descriptions.map({ location, message in
                        .init(
                            message: message,
                            filePath: outputPath(location).string,
                            textRange: .init(
                                startLine: location.line,
                                startColumn: location.column
                            )
                        )
                })
            )
            issues.append(issue)
        }

        let report = SonarQubeReport(rules: rules, issues: issues)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(report)
        return String(data: data, encoding: .utf8)
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
