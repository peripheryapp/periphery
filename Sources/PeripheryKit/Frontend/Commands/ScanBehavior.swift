import Foundation

final class ScanBehavior {
    static func make() -> Self {
        return self.init(configuration: inject(), logger: inject(), xcodebuild: inject())
    }

    private let configuration: Configuration
    private let logger: Logger
    private let xcodebuild: Xcodebuild

    required init(configuration: Configuration, logger: Logger, xcodebuild: Xcodebuild) {
        self.configuration = configuration
        self.logger = logger
        self.xcodebuild = xcodebuild
    }

    func setup(_ config: String?) -> Result<(), PeripheryKitError> {
        configuration.config = config

        do {
            try configuration.applyYamlConfiguration()
        } catch let error as PeripheryKitError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        return .success(())
    }

    func main(_ block: () throws -> ScanResult) -> Result<(), PeripheryKitError> {
        let xcodebuildVersionOutput: String

        do {
            xcodebuildVersionOutput = try xcodebuild.version()
        } catch {
            return .failure(PeripheryKitError.xcodebuildNotConfigured)
        }

        logger.debug(xcodebuildVersionOutput)

        if configuration.guidedSetup {
            let guidedSetup = inject(GuidedSetup.self)

            do {
                try guidedSetup.perform()
            } catch let error as PeripheryKitError {
                return .failure(error)
            } catch {
                return .failure(.underlyingError(error))
            }
        }

        let updateChecker = UpdateChecker.make()
        updateChecker.run()

        let result: ScanResult

        do {
            result = try block()
            let filteredDeclarations = OutputDeclarationFilter.make().filter(result.declarations)
            let sortedDeclarations = DeclarationSorter.sort(filteredDeclarations)
            try configuration.outputFormat.formatter.make().perform(sortedDeclarations)

            if filteredDeclarations.count > 0,
                configuration.outputFormat.supportsAuxiliaryOutput {
                logger.info(
                    colorize("\n➜  ", .boldGreen) +
                        colorize("Seeing false positives?", .bold) +

                        colorize("\n - ", .boldGreen) +
                        "Periphery only analyzes files that are members of the targets you specify." +
                        "\n   References to declarations identified as unused may reside in files that are members of other targets." +

                        colorize("\n - ", .boldGreen) +
                        "By default, Periphery does not assume that all public declarations are in use. " +
                        "\n   You can instruct it to do so with the " +
                        colorize("--retain-public", .bold) +
                        " option." +

                        colorize("\n - ", .boldGreen) +
                        "Periphery is a very precise tool, false positives often turn out to be correct after further investigation."
                )
            }

            updateChecker.notifyIfAvailable()

            if !filteredDeclarations.isEmpty && configuration.strict {
                throw PeripheryKitError.foundIssues(count: filteredDeclarations.count)
            }
        } catch let error as PeripheryKitError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        if configuration.diagnosisConsole, let graph = result.graph {
            let console = DiagnosisConsole(graph: graph)
            console.start()
        }

        return .success(())
    }
}
