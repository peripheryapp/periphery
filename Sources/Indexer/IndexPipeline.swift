import Configuration
import Foundation
import Logger
import Shared
import SourceGraph

public struct IndexPipeline {
    private let plan: IndexPlan
    private let graph: SynchronizedSourceGraph
    private let logger: ContextualLogger
    private let configuration: Configuration
    private let swiftVersion: SwiftVersion

    public init(plan: IndexPlan, graph: SynchronizedSourceGraph, logger: ContextualLogger, configuration: Configuration, swiftVersion: SwiftVersion) {
        self.plan = plan
        self.graph = graph
        self.logger = logger
        self.configuration = configuration
        self.swiftVersion = swiftVersion
    }

    public func perform() throws {
        try SwiftIndexer(
            sourceFiles: plan.sourceFiles,
            graph: graph,
            logger: logger,
            configuration: configuration,
            swiftVersion: swiftVersion
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

        if !plan.xcStringsPaths.isEmpty, !configuration.disableUnusedLocalizedStringAnalysis {
            try XCStringsIndexer(
                files: plan.xcStringsPaths,
                graph: graph,
                logger: logger,
                configuration: configuration
            ).perform()
        }

        graph.indexingComplete()
    }
}
