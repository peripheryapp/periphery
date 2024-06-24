import Shared
import SystemPackage
import SourceGraph

public final class InfoPlistIndexer: Indexer {
    private let infoPlistFiles: Set<FilePath>
    private let graph: SourceGraph
    private let logger: ContextualLogger

    public required init(infoPlistFiles: Set<FilePath>, graph: SourceGraph, logger: Logger = .init(), configuration: Configuration = .shared) {
        self.infoPlistFiles = infoPlistFiles
        self.graph = graph
        self.logger = logger.contextualized(with: "index:infoplist")
        super.init(configuration: configuration)
    }

    public func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: infoPlistFiles)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self = self else { return }

            let elapsed = try Benchmark.measure {
                try InfoPlistParser(path: path)
                    .parse()
                    .forEach { self.graph.add($0)  }
            }

            self.logger.debug("\(path.string) (\(elapsed)s)")
        }
    }
}
