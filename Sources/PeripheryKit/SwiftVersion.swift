import Foundation
import Shared

public struct SwiftVersion {
    public static let current = Self()

    public let version: VersionString
    public let fullVersion: String

    init() {
        let shell: Shell = inject()
        self.fullVersion = try! shell.exec(["swift", "-version"]).trimmed
        self.version = try! SwiftVersionParser.parse(fullVersion)
    }
}
