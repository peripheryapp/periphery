import Foundation

final class XcodebuildVersion {
    static func parse(_ rawVersion: String) -> String {
        let firstLine = String(rawVersion.split(separator: "\n").first ??
            "").trimmed
        return String(firstLine.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).last ?? "")
    }
}
