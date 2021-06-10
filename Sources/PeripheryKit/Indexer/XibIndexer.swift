import Shared
import SystemPackage

public final class XibIndexer {
    public static func make(xibFiles: Set<FilePath>, graph: SourceGraph) -> Self {
        return self.init(xibFiles: xibFiles,
                         graph: graph,
                         logger: inject())
    }

    private let xibFiles: Set<FilePath>
    private let graph: SourceGraph
    private let logger: Logger

    required init(xibFiles: Set<FilePath>, graph: SourceGraph, logger: Logger) {
        self.xibFiles = xibFiles
        self.graph = graph
        self.logger = logger
    }

    public func perform() throws {
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
