import Foundation
import Shared
import PeripheryKit

final class Scan {
    private let configuration: Configuration
    private let logger: Logger

    required init(configuration: Configuration = .shared, logger: Logger = .init()) {
        self.configuration = configuration
        self.logger = logger
    }

    func perform(project: Project) throws -> [ScanResult] {
        if !configuration.indexStorePath.isEmpty {
            logger.warn("When using the '--index-store-path' option please ensure that Xcode is not running. False-positives can occur if Xcode writes to the index store while Periphery is running.")

            if !configuration.skipBuild {
                logger.warn("The '--index-store-path' option implies '--skip-build', specify it to silence this warning.")
                configuration.skipBuild = true
            }
        }

        if configuration.verbose {
            let configYaml = try configuration.asYaml()
            logger.debug("[configuration:begin]\n\(configYaml.trimmed)\n[configuration:end]")
        }

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Inspecting project...")
        }

        let driverPrepareInterval = logger.beginInterval("driver:prepare")
        let driver = try project.driver()
        logger.endInterval(driverPrepareInterval)
        let driverBuildInterval = logger.beginInterval("driver:build")
        try driver.build()
        logger.endInterval(driverBuildInterval)

        let indexInterval = logger.beginInterval("index")
        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Indexing...")
        }

        let graph = SourceGraph.shared
        try driver.index(graph: graph)
        logger.endInterval(indexInterval)

        let analyzeInterval = logger.beginInterval("analyze")
        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Analyzing...")
        }

        try SourceGraphMutatorRunner.perform(graph: graph)
        logger.endInterval(analyzeInterval)

        let resultInterval = logger.beginInterval("result:build")
        let result = ScanResultBuilder.build(for: graph)
        logger.endInterval(resultInterval)

        return result
    }
}
