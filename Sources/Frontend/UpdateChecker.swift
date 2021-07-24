import Foundation
import Shared

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class UpdateChecker: Singleton {
    static func make() -> Self {
        return self.init(logger: inject(), configuration: inject())
    }

    private let logger: ContextualLogger
    private let configuration: Configuration
    private let urlSession: URLSession
    private let latestReleaseURL: URL
    private var latestVersion: String?
    private let semaphore: DispatchSemaphore
    private var error: Error?

    required init(logger: Logger, configuration: Configuration) {
        self.logger = logger.contextualized(with: "update-check")
        self.configuration = configuration
        let config = URLSessionConfiguration.ephemeral
        urlSession = URLSession(configuration: config)
        latestReleaseURL = URL(string: "https://api.github.com/repos/peripheryapp/periphery/releases/latest")!
        semaphore = DispatchSemaphore(value: 0)
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    func run() {
        // We only perform the update check with xcode format because it may interfere with
        // parsing json and csv.
        guard !configuration.disableUpdateCheck,
            configuration.outputFormat.supportsAuxiliaryOutput else { return }

        var urlRequest = URLRequest(url: latestReleaseURL)
        urlRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let task = urlSession.dataTask(with: urlRequest) { [weak self] data, _, error in
            guard let strongSelf = self else { return }

            if let error = error {
                strongSelf.logger.debug("error: \(error.localizedDescription)")
                strongSelf.error = error
                strongSelf.semaphore.signal()
                return
            }

            guard let jsonData = data,
                let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [AnyHashable: Any],
                let tagName = jsonObject["tag_name"] as? String else {
                    var json = "N/A"

                    if let data = data {
                        json = String(data: data, encoding: .utf8) ?? "N/A"
                    }

                    let message = "Failed to identify latest release tag in: \(json)"
                    strongSelf.error = PeripheryError.updateCheckError(message: message)
                    strongSelf.logger.debug(message)
                    strongSelf.semaphore.signal()
                    return
            }

            strongSelf.latestVersion = tagName
            strongSelf.semaphore.signal()
        }

        task.resume()
    }

    func notifyIfAvailable() {
        guard let latestVersion = latestVersion else { return }

        logger.debug("latest: \(latestVersion)")

        guard latestVersion.isVersion(greaterThan: PeripheryVersion) else { return }

        logger.info(colorize("\n* Update Available", .boldGreen))
        let boldLatestVersion = colorize(latestVersion, .bold)
        let boldLocalVersion = colorize(PeripheryVersion, .bold)
        logger.info("Version \(boldLatestVersion) is now available, you are using version \(boldLocalVersion).")
        logger.info("Stay up-to-date to benefit the most from Periphery - we're constantly working to improve accuracy and performance.")
        let boldOption = colorize("--disable-update-check", .bold)
        let boldScan = colorize("scan", .bold)
        logger.info("To disable update checks pass the \(boldOption) option to the \(boldScan) command.")
    }

    func wait() -> Result<String, PeripheryError> {
        let waitResult = semaphore.wait(timeout: .now() + 60)

        if let error = error {
            return .failure(.underlyingError(error))
        }

        if waitResult == .timedOut {
            return .failure(PeripheryError.updateCheckError(message: "Timed out while checking for update."))
        }

        if let latestVersion = latestVersion {
            return .success(latestVersion)
        }

        return .failure(PeripheryError.updateCheckError(message: "Failed to determine latest version."))
    }
}
