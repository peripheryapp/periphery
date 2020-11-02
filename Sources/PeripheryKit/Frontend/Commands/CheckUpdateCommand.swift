import Foundation
import ArgumentParser

public struct CheckUpdateCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "check-update",
        abstract: "Check for available update"
    )

    public init() {}

    public func run() throws {
        let logger: Logger = inject()
        let checker = UpdateChecker.make()
        DispatchQueue.global().async { checker.run() }
        let latestVersion = try checker.wait().get()
        if latestVersion.isVersion(greaterThan: PeripheryVersion) {
            logger.info(colorize("* Update Available", .boldGreen))
            let boldLatestVersion = colorize(latestVersion, .bold)
            let boldLocalVersion = colorize(PeripheryVersion, .bold)
            logger.info("Version \(boldLatestVersion) is now available, you are using version \(boldLocalVersion).")
        } else {
            let boldLatestVersion = colorize(latestVersion, .bold)
            logger.info("You are using the latest version, \(boldLatestVersion).")
        }
    }
}
