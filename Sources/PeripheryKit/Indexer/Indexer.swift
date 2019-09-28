import Foundation

protocol TypeIndexer: AnyObject {
    static func make(buildPlan: BuildPlan, graph: SourceGraph) -> Self
    func perform() throws
}

final class Indexer {
    static func perform(buildPlan: BuildPlan, graph: SourceGraph) throws {
        try make(buildPlan: buildPlan, graph: graph).perform()
    }

    static func make(buildPlan: BuildPlan, graph: SourceGraph) -> Self {
        return self.init(buildPlan: buildPlan,
                        graph: graph)
    }

    private let buildPlan: BuildPlan
    private let graph: SourceGraph

    private let indexers: [TypeIndexer.Type] = [
        SwiftIndexer.self,
        XibIndexer.self
    ]

    required init(buildPlan: BuildPlan, graph: SourceGraph) {
        self.buildPlan = buildPlan
        self.graph = graph
    }

    func perform() throws {
        try indexers.forEach {
            try $0.make(buildPlan: buildPlan, graph: graph).perform()
        }
    }
}
