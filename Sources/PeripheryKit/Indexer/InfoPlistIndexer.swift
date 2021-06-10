import Shared
import SystemPackage

public final class InfoPlistIndexer {
    public static func make(infoPlistFiles: Set<FilePath>, graph: SourceGraph) -> Self {
        return self.init(infoPlistFiles: infoPlistFiles,
                         graph: graph,
                         logger: inject())
    }

    private let infoPlistFiles: Set<FilePath>
    private let graph: SourceGraph
    private let logger: Logger

    required init(infoPlistFiles: Set<FilePath>, graph: SourceGraph, logger: Logger) {
        self.infoPlistFiles = infoPlistFiles
        self.graph = graph
        self.logger = logger
    }

    public func perform() throws {
        let workPool = JobPool<[InfoPlistReference]>()
        let results = try workPool.map(Array(infoPlistFiles)) { [weak self] path in
            guard let strongSelf = self else { return nil }

            var references: [InfoPlistReference] = []

            let elapsed = try Benchmark.measure {
                references = try InfoPlistParser(path: path).parse()
            }

            strongSelf.logger.debug("[index:infoplist] \(path.string) (\(elapsed))s")
            return references
        }

        graph.infoPlistReferences = Array(results.joined())
    }
}
