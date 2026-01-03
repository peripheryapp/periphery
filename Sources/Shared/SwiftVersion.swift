import Extensions
import Foundation

public struct SwiftVersion {
    static let minimumVersion = "5.10"

    public let version: VersionString
    public let fullVersion: String

    public init(shell: Shell) {
        fullVersion = try! shell.exec(["swift", "-version"]).trimmed // swiftlint:disable:this force_try
        version = try! SwiftVersionParser.parse(fullVersion) // swiftlint:disable:this force_try
    }

    public func validateVersion() throws {
        if version.isVersion(lessThan: Self.minimumVersion) {
            throw PeripheryError.swiftVersionUnsupportedError(
                version: fullVersion,
                minimumVersion: Self.minimumVersion
            )
        }
    }
}
