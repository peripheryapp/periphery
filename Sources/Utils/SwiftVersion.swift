import Foundation
import Shared

public struct SwiftVersion {
    public static let current = SwiftVersion()

    static let minimumVersion = "5.9"

    public let version: VersionString
    public let fullVersion: String

    init(shell: Shell = .shared) {
        fullVersion = try! shell.exec(["swift", "-version"]).trimmed // swiftlint:disable:this force_try
        version = try! SwiftVersionParser.parse(fullVersion) // swiftlint:disable:this force_try
    }

    public func validateVersion() throws {
        if Self.current.version.isVersion(lessThan: Self.minimumVersion) {
            throw PeripheryError.swiftVersionUnsupportedError(
                version: SwiftVersion.current.fullVersion,
                minimumVersion: Self.minimumVersion
            )
        }
    }
}
