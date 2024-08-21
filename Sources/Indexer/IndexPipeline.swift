import Foundation
import SourceGraph
import Utils

public struct IndexPipeline {
    private let plan: IndexPlan
    private let graph: SynchronizedSourceGraph
    private let logger: ContextualLogger

    public init(plan: IndexPlan, graph: SynchronizedSourceGraph, logger: ContextualLogger) {
        self.plan = plan
        self.graph = graph
        self.logger = logger
    }

    public func perform() throws {
        try SwiftIndexer(
            sourceFiles: plan.sourceFiles,
            graph: graph,
            logger: logger
        ).perform()

        if !plan.plistPaths.isEmpty {
            try InfoPlistIndexer(infoPlistFiles: plan.plistPaths, graph: graph).perform()
        }

        if !plan.xibPaths.isEmpty {
            try XibIndexer(xibFiles: plan.xibPaths, graph: graph).perform()
        }

        if !plan.xcDataModelPaths.isEmpty {
            try XCDataModelIndexer(files: plan.xcDataModelPaths, graph: graph).perform()
        }

        if !plan.xcMappingModelPaths.isEmpty {
            try XCMappingModelIndexer(files: plan.xcMappingModelPaths, graph: graph).perform()
        }

        graph.indexingComplete()
    }
}
