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
        if configuration.indexStorePath != nil, !configuration.skipBuild {
            logger.warn("The '--index-store-path' option implies '--skip-build', specify it to silence this warning")
            configuration.skipBuild = true
        }

        let configYaml = try configuration.asYaml()
        logger.debug("[configuration:begin]\n\(configYaml.trimmed)\n[configuration:end]")

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Inspecting project...")
        }

        let driver = try project.driver()
        try driver.build()

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Indexing...")
        }

        let graph = SourceGraph()
        try driver.index(graph: graph)

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Analyzing...\n")
        }

        try SourceGraphMutatorRunner.perform(graph: graph)
        return ScanResultBuilder.build(for: graph)
    }
}
