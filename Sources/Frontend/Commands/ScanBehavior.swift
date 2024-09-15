import Foundation
import PeripheryKit
import Shared
import SystemPackage

final class ScanBehavior {
    private let configuration: Configuration
    private let logger: Logger
    private let shell: Shell
    private let swiftVersion: SwiftVersion

    required init(configuration: Configuration, logger: Logger, shell: Shell, swiftVersion: SwiftVersion) {
        self.configuration = configuration
        self.logger = logger
        self.shell = shell
        self.swiftVersion = swiftVersion
    }

    func setup(_ configPath: FilePath?) -> Result<Void, PeripheryError> {
        do {
            try configuration.load(from: configPath, logger: logger)
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        return .success(())
    }

    func main(_ block: (Project) throws -> [ScanResult]) -> Result<Void, PeripheryError> {
        logger.contextualized(with: "version").debug(PeripheryVersion)

        let project: Project

        do {
            logger.debug(swiftVersion.fullVersion)
            try swiftVersion.validateVersion()

            if configuration.guidedSetup {
                project = try GuidedSetup(configuration: configuration, shell: shell, logger: logger).perform()
            } else {
                project = try Project(configuration: configuration, shell: shell, logger: logger)
            }
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
        }

        let updateChecker = UpdateChecker(logger: logger, configuration: configuration)
        updateChecker.run()

        let results: [ScanResult]

        do {
            results = try block(project)

            let interval = logger.beginInterval("result:output")
            var baseline: Baseline?

            if let baselinePath = configuration.baseline {
                let data = try Data(contentsOf: baselinePath.url)
                baseline = try JSONDecoder().decode(Baseline.self, from: data)
            }

            let filteredResults = try OutputDeclarationFilter(configuration: configuration, logger: logger).filter(results, with: baseline)

            if let baselinePath = configuration.writeBaseline {
                let usrs = filteredResults
                    .flatMapSet { $0.usrs }
                    .union(baseline?.usrs ?? [])
                let baseline = Baseline.v1(usrs: usrs.sorted())
                let data = try JSONEncoder().encode(baseline)
                try data.write(to: baselinePath.url)
            }

            let output = try configuration.outputFormat.formatter.init(configuration: configuration).format(filteredResults)

            if configuration.outputFormat.supportsAuxiliaryOutput {
                logger.info("", canQuiet: true)
            }

            logger.info(output, canQuiet: false)
            logger.endInterval(interval)

            updateChecker.notifyIfAvailable()

            if !filteredResults.isEmpty, configuration.strict {
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
