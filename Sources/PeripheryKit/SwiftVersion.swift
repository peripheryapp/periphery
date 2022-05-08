import Foundation
import Shared

public struct SwiftVersion {
    public static let current = Self()

    static let minimumVersion = "5.5"

    public let version: VersionString
    public let fullVersion: String

    init() {
        let shell: Shell = inject()
        self.fullVersion = try! shell.exec(["swift", "-version"]).trimmed
        self.version = try! SwiftVersionParser.parse(fullVersion)
    }

    public func validateVersion() throws {
        if Self.current.version.isVersion(lessThan: Self.minimumVersion) {
            throw PeripheryError.swiftVersionUnsupportedError(
                version: SwiftVersion.current.fullVersion,
                minimumVersion: Self.minimumVersion)
        }
    }
}
