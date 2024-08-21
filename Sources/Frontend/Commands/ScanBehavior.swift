import Foundation
import PeripheryKit
import Shared
import SystemPackage
import Configuration
import Utils

final class ScanBehavior {
    private let configuration: Configuration
    private let logger: Logger

    required init(configuration: Configuration = .shared, logger: Logger = .init()) {
        self.configuration = configuration
        self.logger = logger
    }

    func setup(_ configPath: FilePath?) -> Result<Void, PeripheryError> {
        do {
            try configuration.load(from: configPath)
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
            logger.debug(SwiftVersion.current.fullVersion)
            try SwiftVersion.current.validateVersion()

            if configuration.guidedSetup {
                project = try GuidedSetup().perform()
            } else {
                project = try Project.identify()
            }
        } catch let error as PeripheryError {
            return .failure(error)
        } catch {
            return .failure(.underlyingError(error))
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
