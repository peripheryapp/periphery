import Configuration
import Logger
import Shared
import SourceGraph
import SystemPackage

final class InfoPlistIndexer: Indexer {
    enum PlistError: Error {
        case failedToParse(path: FilePath, underlyingError: Error)
    }

    private let infoPlistFiles: Set<FilePath>
    private let graph: SourceGraphMutex
    private let logger: ContextualLogger

    required init(infoPlistFiles: Set<FilePath>, graph: SourceGraphMutex, logger: ContextualLogger, configuration: Configuration) {
        self.infoPlistFiles = infoPlistFiles
        self.graph = graph
        self.logger = logger.contextualized(with: "infoplist")
        super.init(configuration: configuration)
    }

    func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: infoPlistFiles)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self else { return }

            let elapsed = try Benchmark.measure {
                do {
                    let refs = try InfoPlistParser(path: path)
                        .parse()
                    self.graph.withLock { graph in
                        refs.forEach { graph.add($0) }
                    }
                } catch {
                    throw PlistError.failedToParse(path: path, underlyingError: error)
                }
            }

            logger.debug("\(path.string) (\(elapsed)s)")
        }
    }
}
