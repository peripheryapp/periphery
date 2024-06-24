import Foundation

public struct SwiftVersionParser {
    public static func parse(_ fullVersion: String) throws -> VersionString {
        guard let rawVersion = fullVersion.components(separatedBy: "Swift version").last?.split(separator: " ").first else {
            throw PeripheryError.swiftVersionParseError(fullVersion: fullVersion)
        }

        let version = rawVersion.split(separator: "-").first ?? rawVersion
        return String(version)
    }
}
