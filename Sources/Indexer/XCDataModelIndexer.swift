import Configuration
import Logger
import Shared
import SourceGraph
import SystemPackage

final class XCDataModelIndexer: Indexer {
    enum XCDataModelError: Error {
        case failedToParse(path: FilePath, underlyingError: Error)
    }
    private let files: Set<FilePath>
    private let graph: SynchronizedSourceGraph
    private let logger: ContextualLogger

    required init(files: Set<FilePath>, graph: SynchronizedSourceGraph, logger: ContextualLogger, configuration: Configuration) {
        self.files = files
        self.graph = graph
        self.logger = logger.contextualized(with: "xcdatamodel")
        super.init(configuration: configuration)
    }

    func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: files)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self else { return }

            let elapsed = try Benchmark.measure {
                do {
                    try XCDataModelParser(path: path)
                        .parse()
                        .forEach { self.graph.add($0) }
                } catch {
                    throw XCDataModelError.failedToParse(path: path, underlyingError: error)
                }
            }

            logger.debug("\(path.string) (\(elapsed)s)")
        }
    }
}
