import Shared
import SystemPackage

public final class XCMappingModelIndexer {
    public static func make(files: Set<FilePath>, graph: SourceGraph) -> Self {
        return self.init(files: files,
                         graph: graph,
                         logger: inject())
    }

    private let files: Set<FilePath>
    private let graph: SourceGraph
    private let logger: Logger

    required init(files: Set<FilePath>, graph: SourceGraph, logger: Logger) {
        self.files = files
        self.graph = graph
        self.logger = logger
    }

    public func perform() throws {
        try JobPool(jobs: Array(files)).forEach { [weak self] path in
            guard let self = self else { return }

            let elapsed = try Benchmark.measure {
                try XCMappingModelParser(path: path)
                    .parse()
                    .forEach { self.graph.add($0) }
            }

            self.logger.debug("[index:xcmappingmodel] \(path.string) (\(elapsed))s")
        }
    }
}
