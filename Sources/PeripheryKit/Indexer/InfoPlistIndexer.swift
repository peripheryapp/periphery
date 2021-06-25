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
        try JobPool(jobs: Array(infoPlistFiles)).forEach { [weak self] path in
            guard let self = self else { return }

            let elapsed = try Benchmark.measure {
                try InfoPlistParser(path: path)
                    .parse()
                    .forEach { self.graph.add($0)  }
            }

            self.logger.debug("[index:infoplist] \(path.string) (\(elapsed))s")
        }
    }
}
