import PathKit

final class InfoPlistIndexer {
    static func make(infoPlistFiles: Set<Path>, graph: SourceGraph) -> Self {
        return self.init(infoPlistFiles: infoPlistFiles,
                         graph: graph,
                         logger: inject())
    }

    private let infoPlistFiles: Set<Path>
    private let graph: SourceGraph
    private let logger: Logger

    required init(infoPlistFiles: Set<Path>, graph: SourceGraph, logger: Logger) {
        self.infoPlistFiles = infoPlistFiles
        self.graph = graph
        self.logger = logger
    }

    func perform() throws {
        let workPool = JobPool<[InfoPlistReference]>()
        let results = try workPool.map(Array(infoPlistFiles)) { [weak self] path in
            guard let strongSelf = self else { return nil }

            var references: [InfoPlistReference] = []

            let elapsed = Benchmark.measure {
                references = InfoPlistParser(path: path).parse()
            }

            strongSelf.logger.debug("[index:infoplist] \(path.string) (\(elapsed))s")
            return references
        }

        graph.infoPlistReferences = Array(results.joined())
    }
}
