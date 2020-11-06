import Foundation

final class XcodebuildSettingsParser {
    private let lines: [String]

    init(settings: String) {
        self.lines = settings.split(separator: "\n").map { String($0) }
    }

    func buildTargets(action: String) -> [String] {
        let sectionTitle = "Build settings for action \(action) and target"

        let sectionIndicies = lines.indices.compactMap {
            lines[$0].contains(sectionTitle) ? $0 : nil
        }

        return sectionIndicies.compactMap {
            if let targetNameLine = lines[$0..<lines.endIndex].first(where: { $0.contains(" TARGET_NAME =") }) {
                if let name = targetNameLine.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true).last {
                    return String(name).trimmed
                }
            }

            return nil
        }
    }
}
