import Configuration
import Logger
import Shared
import SourceGraph
import SystemPackage

final class XibIndexer: Indexer {
    enum XibError: Error {
        case failedToParse(path: FilePath, underlyingError: Error)
    }
    private let xibFiles: Set<FilePath>
    private let graph: SynchronizedSourceGraph
    private let logger: ContextualLogger

    required init(xibFiles: Set<FilePath>, graph: SynchronizedSourceGraph, logger: ContextualLogger, configuration: Configuration) {
        self.xibFiles = xibFiles
        self.graph = graph
        self.logger = logger.contextualized(with: "xib")
        super.init(configuration: configuration)
    }

    func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: xibFiles)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] xibPath in
            guard let self else { return }

            let elapsed = try Benchmark.measure {
                do {
                    try XibParser(path: xibPath)
                        .parse()
                        .forEach { self.graph.add($0) }
                } catch {
                    throw XibError.failedToParse(path: xibPath, underlyingError: error)
                }
            }

            logger.debug("\(xibPath.string) (\(elapsed)s)")
        }
    }
}
