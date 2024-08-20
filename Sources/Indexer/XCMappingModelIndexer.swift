import Shared
import SourceGraph
import SystemPackage

final class XCMappingModelIndexer: Indexer {
    private let files: Set<FilePath>
    private let graph: SynchronizedSourceGraph
    private let logger: ContextualLogger

    required init(files: Set<FilePath>, graph: SynchronizedSourceGraph, logger: Logger = .init(), configuration: Configuration = .shared) {
        self.files = files
        self.graph = graph
        self.logger = logger.contextualized(with: "index:xcmappingmodel")
        super.init(configuration: configuration)
    }

    func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: files)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self else { return }

            let elapsed = try Benchmark.measure {
                try XCMappingModelParser(path: path)
                    .parse()
                    .forEach { self.graph.add($0) }
            }

            logger.debug("\(path.string) (\(elapsed)s)")
        }
    }
}
