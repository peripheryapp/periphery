import PathKit

final class XibIndexer {
    static func make(xibFiles: Set<Path>, graph: SourceGraph) -> Self {
        return self.init(xibFiles: xibFiles,
                         graph: graph,
                         logger: inject())
    }

    private let xibFiles: Set<Path>
    private let graph: SourceGraph
    private let logger: Logger

    required init(xibFiles: Set<Path>, graph: SourceGraph, logger: Logger) {
        self.xibFiles = xibFiles
        self.graph = graph
        self.logger = logger
    }

    func perform() throws {
        let workPool = JobPool<[XibReference]>()
        let results = try workPool.map(Array(xibFiles)) { [weak self] xibPath in
            guard let strongSelf = self else { return nil }

            var references: [XibReference] = []

            let elapsed = try Benchmark.measure {
                references = try XibParser(path: xibPath).parse()
            }

            strongSelf.logger.debug("[index:xib] \(xibPath.string) (\(elapsed))s")
            return references
        }

        graph.xibReferences = Array(results.joined())
    }
}
