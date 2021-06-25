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
        try JobPool(jobs: Array(xibFiles)).forEach { [weak self] xibPath in
            guard let self = self else { return }

            let elapsed = try Benchmark.measure {
                try XibParser(path: xibPath)
                    .parse()
                    .forEach { self.graph.add($0) }
            }

            self.logger.debug("[index:xib] \(xibPath.string) (\(elapsed))s")
        }
    }
}
