import Foundation
import Shared

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class UpdateChecker {
    private let logger: Logger
    private let debugLogger: ContextualLogger
    private let configuration: Configuration
    private let urlSession: URLSession
    private let latestReleaseURL: URL
    private var latestVersion: String?
    private let semaphore: DispatchSemaphore
    private var error: Error?

    public required init(logger: Logger = .init(), configuration: Configuration = .shared) {
        self.logger = logger
        self.debugLogger = logger.contextualized(with: "update-check")
        self.configuration = configuration
        let config = URLSessionConfiguration.ephemeral
        urlSession = URLSession(configuration: config)
        latestReleaseURL = URL(string: "https://api.github.com/repos/peripheryapp/periphery/releases/latest")!
        semaphore = DispatchSemaphore(value: 0)
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    public func run() {
        // We only perform the update check with xcode format because it may interfere with
        // parsing json and csv.
        guard !configuration.disableUpdateCheck,
            configuration.outputFormat.supportsAuxiliaryOutput else { return }

        var urlRequest = URLRequest(url: latestReleaseURL)
        urlRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let task = urlSession.dataTask(with: urlRequest) { [weak self] data, _, error in
            // swiftlint:disable:next self_binding
            guard let strongSelf = self else { return }

            if let error {
                strongSelf.debugLogger.debug("error: \(error.localizedDescription)")
                strongSelf.error = error
                strongSelf.semaphore.signal()
                return
            }

            guard let jsonData = data,
                let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [AnyHashable: Any],
                let tagName = jsonObject["tag_name"] as? String else {
                    var json = "N/A"

                    if let data {
                        let decoded = String(decoding: data, as: UTF8.self)
                        if !decoded.isEmpty {
                            json = decoded
                        }
                    }

                    let message = "Failed to identify latest release tag in: \(json)"
                    strongSelf.error = PeripheryError.updateCheckError(message: message)
                    strongSelf.debugLogger.debug(message)
                    strongSelf.semaphore.signal()
                    return
            }

            strongSelf.latestVersion = tagName
            strongSelf.semaphore.signal()
        }

        task.resume()
    }

    func notifyIfAvailable() {
        guard let latestVersion else { return }

        debugLogger.debug("latest: \(latestVersion)")

        guard latestVersion.isVersion(greaterThan: PeripheryVersion) else { return }

        logger.info(colorize("\n* Update Available", .boldGreen))
        let boldLatestVersion = colorize(latestVersion, .bold)
        let boldLocalVersion = colorize(PeripheryVersion, .bold)
        logger.info("Version \(boldLatestVersion) is now available, you are using version \(boldLocalVersion).")
        logger.info("Release notes: https://github.com/peripheryapp/periphery/releases/tag/\(latestVersion)")
        let boldOption = colorize("--disable-update-check", .bold)
        let boldScan = colorize("scan", .bold)
        logger.info("To disable update checks pass the \(boldOption) option to the \(boldScan) command.")
    }

    public func wait() -> Result<String, PeripheryError> {
        let waitResult = semaphore.wait(timeout: .now() + 60)

        if let error {
            return .failure(.underlyingError(error))
        }

        if waitResult == .timedOut {
            return .failure(PeripheryError.updateCheckError(message: "Timed out while checking for update."))
        }

        if let latestVersion {
            return .success(latestVersion)
        }

        return .failure(PeripheryError.updateCheckError(message: "Failed to determine latest version."))
    }
}
