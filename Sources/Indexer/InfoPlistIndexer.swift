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
    private let graph: SynchronizedSourceGraph
    private let logger: ContextualLogger

    required init(infoPlistFiles: Set<FilePath>, graph: SynchronizedSourceGraph, logger: ContextualLogger, configuration: Configuration) {
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
                    try InfoPlistParser(path: path)
                        .parse()
                        .forEach { self.graph.add($0) }
                } catch {
                    throw PlistError.failedToParse(path: path, underlyingError: error)
                }
            }

            logger.debug("\(path.string) (\(elapsed)s)")
        }
    }
}
