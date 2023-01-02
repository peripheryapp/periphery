import Shared
import SystemPackage

public final class XCDataModelIndexer: Indexer {
    private let files: Set<FilePath>
    private let graph: SourceGraph
    private let logger: ContextualLogger

    public required init(files: Set<FilePath>, graph: SourceGraph, logger: Logger = .init(), configuration: Configuration = .shared) {
        self.files = files
        self.graph = graph
        self.logger = logger.contextualized(with: "index:xcdatamodel")
        super.init(configuration: configuration)
    }

    public func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: files)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self = self else { return }

            let elapsed = try Benchmark.measure {
                try XCDataModelParser(path: path)
                    .parse()
                    .forEach { self.graph.add($0) }
            }

            self.logger.debug("\(path.string) (\(elapsed)s)")
        }
    }
}
