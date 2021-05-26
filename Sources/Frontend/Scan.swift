import Foundation
import PathKit
import Shared
import PeripheryKit

final class Scan: Injectable {
    static func make() -> Self {
        return self.init(configuration: inject(),
                         logger: inject())
    }

    private let configuration: Configuration
    private let logger: Logger

    required init(configuration: Configuration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
    }

    func perform(project: Project) throws -> [ScanResult] {
        logger.debug("[version] \(PeripheryVersion)")
        let configYaml = try configuration.asYaml()
        logger.debug("[configuration]\n--- # .periphery.yml\n\(configYaml.trimmed)\n")

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

        try Analyzer.perform(graph: graph)
        return ScanResultBuilder.build(for: graph)
    }
}
