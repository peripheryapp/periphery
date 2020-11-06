import Foundation
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

    func setup(_ config: String?) -> Result<(), PeripheryError> {
        configuration.config = config

        do {
            try configuration.applyYamlConfiguration()
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        return .success(())
    }

    func main(_ block: (Project) throws -> ScanResult) -> Result<(), PeripheryError> {
        let project: Project

        do {
            project = try Project.identify()
            try project.validateEnvironment()
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        if configuration.guidedSetup {
            do {
                try GuidedSetup.make(project: project).perform()
            } catch let error as PeripheryError {
                return .failure(error)
            } catch {
                return .failure(.underlyingError(error))
            }
        }

        let updateChecker = UpdateChecker.make()
        updateChecker.run()

        let result: ScanResult

        do {
            result = try block(project)
            let filteredDeclarations = OutputDeclarationFilter.make().filter(result.declarations)
            let sortedDeclarations = DeclarationSorter.sort(filteredDeclarations)
            try configuration.outputFormat.formatter.make().perform(sortedDeclarations)

            if filteredDeclarations.count > 0,
                configuration.outputFormat.supportsAuxiliaryOutput {
                logger.info(
                    colorize("\n* ", .boldGreen) +
                        colorize("Seeing false positives?", .bold) +

                        colorize("\n - ", .boldGreen) +
                        "Periphery only analyzes files that are members of the targets you specify." +
                        "\n   References to declarations identified as unused may reside in files that are members of other targets, e.g test targets" +

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

            if !filteredDeclarations.isEmpty && configuration.strict {
                throw PeripheryError.foundIssues(count: filteredDeclarations.count)
            }
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        return .success(())
    }
}
