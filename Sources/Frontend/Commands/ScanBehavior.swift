import Foundation
import SystemPackage
import Shared
import PeripheryKit

final class ScanBehavior {
    private let configuration: Configuration
    private let logger: Logger

    required init(configuration: Configuration = .shared, logger: Logger = .init()) {
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
        logger.contextualized(with: "version").debug(PeripheryVersion)
        let project: Project

        if configuration.guidedSetup {
            do {
                project = try GuidedSetup().perform()
            } catch let error as PeripheryError {
                return .failure(error)
            } catch {
                return .failure(.underlyingError(error))
            }
        } else {
            project = Project.identify()

            do {
                // Guided setup performs validation itself once the type has been determined.
                try project.validateEnvironment()
            } catch let error as PeripheryError {
                return .failure(error)
            } catch {
                return .failure(.underlyingError(error))
            }
        }

        let updateChecker = UpdateChecker()
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

            let filteredResults = try OutputDeclarationFilter().filter(results, with: baseline)

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
