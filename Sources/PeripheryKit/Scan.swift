import Foundation
import PathKit

public final class Scan: Injectable {
    public static func make() -> Self {
        return self.init(configuration: inject(),
                         xcodebuild: inject(),
                         logger: inject())
    }

    private let configuration: Configuration
    private let xcodebuild: Xcodebuild
    private let logger: Logger

    public required init(configuration: Configuration,
                         xcodebuild: Xcodebuild,
                         logger: Logger) {
        self.configuration = configuration
        self.xcodebuild = xcodebuild
        self.logger = logger
    }

    public func perform() throws -> ScanResult {
        logger.debug("[version] \(PeripheryVersion)")
        let configYaml = try configuration.asYaml()
        logger.debug("[configuration]\n--- # .periphery.yml\n\(configYaml.trimmed)\n")

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Inspecting project...")
        }

        let project = try Project.build()

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Indexing...")
        }

        let graph = SourceGraph()
        try project.index(graph: graph)

//        try Indexer.perform(buildPlan: buildPlan, graph: graph, project: project)

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Analyzing...\n")
        }

        try Analyzer.perform(graph: graph)

        let reducer = RedundantDeclarationReducer(declarations: graph.dereferencedDeclarations)
        let reducedDeclarations = reducer.reduce()

        return ScanResult(declarations: reducedDeclarations, graph: graph)
    }
}
