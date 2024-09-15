import Configuration
import Foundation
import Logger
import SourceGraph

public struct IndexPipeline {
    private let plan: IndexPlan
    private let graph: SynchronizedSourceGraph
    private let logger: ContextualLogger
    private let configuration: Configuration

    public init(plan: IndexPlan, graph: SynchronizedSourceGraph, logger: ContextualLogger, configuration: Configuration) {
        self.plan = plan
        self.graph = graph
        self.logger = logger
        self.configuration = configuration
    }

    public func perform() throws {
        try SwiftIndexer(
            sourceFiles: plan.sourceFiles,
            graph: graph,
            logger: logger,
            configuration: configuration
        ).perform()

        if !plan.plistPaths.isEmpty {
            try InfoPlistIndexer(
                infoPlistFiles: plan.plistPaths,
                graph: graph,
                logger: logger,
                configuration: configuration
            ).perform()
        }

        if !plan.xibPaths.isEmpty {
            try XibIndexer(
                xibFiles: plan.xibPaths,
                graph: graph,
                logger: logger,
                configuration: configuration
            ).perform()
        }

        if !plan.xcDataModelPaths.isEmpty {
            try XCDataModelIndexer(
                files: plan.xcDataModelPaths,
                graph: graph,
                logger: logger,
                configuration: configuration
            ).perform()
        }

        if !plan.xcMappingModelPaths.isEmpty {
            try XCMappingModelIndexer(
                files: plan.xcMappingModelPaths,
                graph: graph,
                logger: logger,
                configuration: configuration
            ).perform()
        }

        graph.indexingComplete()
    }
}
