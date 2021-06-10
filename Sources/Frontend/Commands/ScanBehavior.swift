import Foundation
import SystemPackage
import Shared
import PeripheryKit

final class ScanBehavior {
    static func make() -> Self {
        return self.init(configuration: inject(), logger: inject())
    }

    private let configuration: Configuration
    private let logger: Logger

    required init(configuration: Configuration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
    }

    func setup(_ configPath: String?) -> Result<(), PeripheryError> {
        do {
            var path: FilePath?

            if let configPath = configPath {
                path = FilePath(configPath)
            }
            try configuration.load(from: path)
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        return .success(())
    }

    func main(_ block: (Project) throws -> [ScanResult]) -> Result<(), PeripheryError> {
        if configuration.guidedSetup {
            do {
                try GuidedSetup.make().perform()
            } catch let error as PeripheryError {
                return .failure(error)
            } catch {
                return .failure(.underlyingError(error))
            }
        }

        let project: Project

        do {
            project = try Project.identify()
            try project.validateEnvironment()
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        let updateChecker = UpdateChecker.make()
        updateChecker.run()

        let results: [ScanResult]

        do {
            results = try block(project)
            let filteredResults = OutputDeclarationFilter.make().filter(results)
            let sortedResults = filteredResults.sorted { $0.declaration < $1.declaration }
            try configuration.outputFormat.formatter.make().perform(sortedResults)

            if filteredResults.count > 0,
                configuration.outputFormat.supportsAuxiliaryOutput {
                logger.info(
                    colorize("\n* ", .boldGreen) +
                        colorize("Seeing false positives?", .bold) +

                        colorize("\n - ", .boldGreen) +
                        "Periphery only analyzes files that are members of the targets you specify." +
                        "\n   References to declarations identified as unused may reside in files that are members of other targets, e.g test targets." +

                        colorize("\n - ", .boldGreen) +
                        "By default, Periphery does not assume that all public declarations are in use. " +
                        "\n   You can instruct it to do so with the " +
                        colorize("--retain-public", .bold) +
                        " option." +

                        colorize("\n - ", .boldGreen) +
                        "Periphery is a very precise tool, false positives often turn out to be correct after further investigation." +

                        colorize("\n - ", .boldGreen) +
                        "If it really is a false positive, please report it - https://github.com/peripheryapp/periphery/issues."
                )
            }

            updateChecker.notifyIfAvailable()

            if !filteredResults.isEmpty && configuration.strict {
                throw PeripheryError.foundIssues(count: filteredResults.count)
            }
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        return .success(())
    }
}
