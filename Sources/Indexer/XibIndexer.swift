import Shared
import SystemPackage
import SourceGraph

public final class XibIndexer: Indexer {
    private let xibFiles: Set<FilePath>
    private let graph: SourceGraph
    private let logger: ContextualLogger

    public required init(xibFiles: Set<FilePath>, graph: SourceGraph, logger: Logger = .init(), configuration: Configuration = .shared) {
        self.xibFiles = xibFiles
        self.graph = graph
        self.logger = logger.contextualized(with: "index:xib")
        super.init(configuration: configuration)
    }

    public func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: xibFiles)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] xibPath in
            guard let self = self else { return }

            let elapsed = try Benchmark.measure {
                try XibParser(path: xibPath)
                    .parse()
                    .forEach { self.graph.add($0) }
            }

            self.logger.debug("\(xibPath.string) (\(elapsed)s)")
        }
    }
}
