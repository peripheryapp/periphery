import Foundation

protocol TypeIndexer: AnyObject {
    static func make(buildPlan: BuildPlan, graph: SourceGraph, project: XcodeProjectlike) throws -> Self
    func perform() throws
}

final class Indexer {
    static func perform(buildPlan: BuildPlan, graph: SourceGraph, project: XcodeProjectlike) throws {
        try make(buildPlan: buildPlan, graph: graph, project: project).perform()
    }

    static func make(buildPlan: BuildPlan, graph: SourceGraph, project: XcodeProjectlike) -> Self {
        return self.init(buildPlan: buildPlan, graph: graph, project: project, configuration: inject())
    }

    private let buildPlan: BuildPlan
    private let graph: SourceGraph
    private let project: XcodeProjectlike

    private let indexers: [TypeIndexer.Type]

    required init(buildPlan: BuildPlan, graph: SourceGraph, project: XcodeProjectlike, configuration: Configuration) {
        self.buildPlan = buildPlan
        self.graph = graph
        self.project = project
        self.indexers = [
            configuration.useIndexStore ? IndexStoreIndexer.self : SourceKitIndexer.self,
            XibIndexer.self
        ]
    }

    func perform() throws {
        try indexers.forEach {
            try $0.make(buildPlan: buildPlan, graph: graph, project: project).perform()
        }
    }
}
