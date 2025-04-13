import Configuration
import Foundation
import Indexer
import Logger
import PeripheryKit
import ProjectDrivers
import Shared
import SourceGraph

final class Scan {
    private let configuration: Configuration
    private let logger: Logger
    private let graph: SourceGraph
    private let swiftVersion: SwiftVersion

    required init(configuration: Configuration, logger: Logger, swiftVersion: SwiftVersion) {
        self.configuration = configuration
        self.logger = logger
        self.swiftVersion = swiftVersion
        graph = SourceGraph(configuration: configuration)
    }

    func perform(project: Project) throws -> [ScanResult] {
        if !configuration.indexStorePath.isEmpty {
            logger.warn("When using the '--index-store-path' option please ensure that Xcode is not running. False-positives can occur if Xcode writes to the index store while Periphery is running.")

            if !configuration.skipBuild {
                logger.warn("The '--index-store-path' option implies '--skip-build', specify it to silence this warning.")
                configuration.skipBuild = true
            }
        }

        let driver = try setup(project)

        // Output configuration after project setup as the driver may alter it.
        if configuration.verbose {
            let configYaml = try configuration.asYaml()
            logger.debug("[configuration:begin]\n\(configYaml.trimmed)\n[configuration:end]")
        }

        try build(driver)
        try index(driver)
        try analyze()
        return buildResults()
    }

    // MARK: - Private

    private func setup(_ project: Project) throws -> ProjectDriver {
        let driverSetupInterval = logger.beginInterval("driver:setup")
        let driver = try project.driver()
        logger.endInterval(driverSetupInterval)
        return driver
    }

    private func build(_ driver: ProjectDriver) throws {
        let driverBuildInterval = logger.beginInterval("driver:build")
        try driver.build()
        logger.endInterval(driverBuildInterval)
    }

    private func index(_ driver: ProjectDriver) throws {
        let indexInterval = logger.beginInterval("index")

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = Logger.colorize("*", .boldGreen)
            logger.info("\(asterisk) Indexing...")
        }

        let indexLogger = logger.contextualized(with: "index")
        let plan = try driver.plan(logger: indexLogger)
        let syncSourceGraph = SynchronizedSourceGraph(graph: graph)
        let pipeline = IndexPipeline(plan: plan, graph: syncSourceGraph, logger: indexLogger, configuration: configuration)
        try pipeline.perform()
        logger.endInterval(indexInterval)
    }

    private func analyze() throws {
        let analyzeInterval = logger.beginInterval("analyze")

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = Logger.colorize("*", .boldGreen)
            logger.info("\(asterisk) Analyzing...")
        }

        try SourceGraphMutatorRunner(
            graph: graph,
            logger: logger,
            configuration: configuration,
            swiftVersion: swiftVersion
        ).perform()
        logger.endInterval(analyzeInterval)
    }

    private func buildResults() -> [ScanResult] {
        let resultInterval = logger.beginInterval("result:build")
        let results = ScanResultBuilder.build(for: graph)
        logger.endInterval(resultInterval)
        return results
    }
}
