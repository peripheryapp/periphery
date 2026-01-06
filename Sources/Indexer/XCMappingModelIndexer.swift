import Configuration
import Logger
import Shared
import SourceGraph
import SystemPackage

final class XCMappingModelIndexer: Indexer {
    private let files: Set<FilePath>
    private let graph: SourceGraphMutex
    private let logger: ContextualLogger

    required init(files: Set<FilePath>, graph: SourceGraphMutex, logger: ContextualLogger, configuration: Configuration) {
        self.files = files
        self.graph = graph
        self.logger = logger.contextualized(with: "xcmappingmodel")
        super.init(configuration: configuration)
    }

    func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: files)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self else { return }

            let elapsed = try Benchmark.measure {
                let refs = try XCMappingModelParser(path: path)
                    .parse()
                self.graph.withLock { graph in
                    refs.forEach { graph.add($0) }
                }
            }

            logger.debug("\(path.string) (\(elapsed)s)")
        }
    }
}
