import Foundation
import Commandant
import Result

public struct CheckUpdateCommand: CommandProtocol {
    public let verb = "check-update"
    public let function = "Check for available update"

    public init() {}

    public func run(_ options: ScanOptions) -> Result<(), PeripheryKitError> {
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
                let boldBrewCmd = colorize("brew cask upgrade periphery", .bold)
                logger.info("Update now: \(boldBrewCmd)")
            } else {
                let boldLatestVersion = colorize(latestVersion, .bold)
                logger.info("You are using the latest version, \(boldLatestVersion).")
            }

            return .success(())
        }
    }
}
