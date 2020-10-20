import PathKit

final class XibIndexer: TypeIndexer {
    static func make(buildPlan: BuildPlan, graph: SourceGraph, project: XcodeProjectlike) -> Self {
        return self.init(buildPlan: buildPlan,
                         graph: graph,
                         logger: inject())
    }

    private let buildPlan: BuildPlan
    private let graph: SourceGraph
    private let logger: Logger

    required init(buildPlan: BuildPlan, graph: SourceGraph, logger: Logger) {
        self.buildPlan = buildPlan
        self.graph = graph
        self.logger = logger
    }

    func perform() throws {
        var jobs: [Path] = []

        for target in buildPlan.targets {
            jobs.append(contentsOf: try target.xibFiles())
        }

        let workPool = JobPool<[XibReference]>()
        let results = try workPool.map(jobs) { [weak self] xibPath in
            guard let strongSelf = self else { return nil }

            var references: [XibReference] = []

            let elapsed = Benchmark.measure {
                references = XibParser(path: xibPath).parse()
            }

            strongSelf.logger.debug("[index:xib] \(xibPath.string) (\(elapsed))s")
            return references
        }

        graph.xibReferences = Array(results.joined())
    }
}
