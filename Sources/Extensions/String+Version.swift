import Foundation

public typealias VersionString = String

public extension VersionString {
    /// Inner comparison utility to handle same versions with different length. (Ex: "1.0.0" & "1.0")
    private func compare(toVersion targetVersion: String) -> ComparisonResult {
        let versionDelimiter = "."
        var result: ComparisonResult = .orderedSame
        var versionComponents = components(separatedBy: versionDelimiter)
        var targetComponents = targetVersion.components(separatedBy: versionDelimiter)
        let spareCount = versionComponents.count - targetComponents.count

        if spareCount == 0 {
            result = compare(targetVersion, options: .numeric)
        } else {
            let spareZeros = repeatElement("0", count: abs(spareCount))
            if spareCount > 0 {
                targetComponents.append(contentsOf: spareZeros)
            } else {
                versionComponents.append(contentsOf: spareZeros)
            }
            result = versionComponents.joined(separator: versionDelimiter)
                .compare(targetComponents.joined(separator: versionDelimiter), options: .numeric)
        }
        return result
    }

    func isVersion(equalTo targetVersion: String) -> Bool { compare(toVersion: targetVersion) == .orderedSame }
    func isVersion(greaterThan targetVersion: String) -> Bool { compare(toVersion: targetVersion) == .orderedDescending }
    func isVersion(greaterThanOrEqualTo targetVersion: String) -> Bool { compare(toVersion: targetVersion) != .orderedAscending }
    func isVersion(lessThan targetVersion: String) -> Bool { compare(toVersion: targetVersion) == .orderedAscending }
    func isVersion(lessThanOrEqualTo targetVersion: String) -> Bool { compare(toVersion: targetVersion) != .orderedDescending }
}
