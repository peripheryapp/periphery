import Foundation
import Commandant
import Result
import ArgumentParser

public struct CheckUpdateCommand: CommandProtocol, ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "check-update",
        abstract: "Check for available update"
    )
    public let verb = configuration.commandName!
    public let function = configuration.abstract

    public init() {}

    public func run() throws {
        try run(NoOptions()).get()
    }

    public func run(_ options: NoOptions<PeripheryKitError>) -> Result<(), PeripheryKitError> {
        let logger: Logger = inject()
        let checker = UpdateChecker.make()
        DispatchQueue.global().async { checker.run() }
        let result = checker.wait()

        switch result {
        case .failure(let error):
            return .failure(error)
        case .success(let latestVersion):
            if latestVersion.isVersion(greaterThan: PeripheryVersion) {
                logger.info(colorize("➜  Update Available", .boldGreen))
                let boldLatestVersion = colorize(latestVersion, .bold)
                let boldLocalVersion = colorize(PeripheryVersion, .bold)
                logger.info("Version \(boldLatestVersion) is now available, you are using version \(boldLocalVersion).")
            } else {
                let boldLatestVersion = colorize(latestVersion, .bold)
                logger.info("You are using the latest version, \(boldLatestVersion).")
            }

            return .success(())
        }
    }
}
