import ArgumentParser
import Configuration
import Foundation
import Logger

struct CheckUpdateCommand: FrontendCommand {
    static let configuration = CommandConfiguration(
        commandName: "check-update",
        abstract: "Check for available update"
    )

    func run() throws {
        let configuration = Configuration()
        let logger = Logger(configuration: configuration)
        let checker = UpdateChecker(logger: logger, configuration: configuration)
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
