import Shared
import SystemPackage

public final class XibIndexer: IndexExcludable {
    public static func make(xibFiles: Set<FilePath>, graph: SourceGraph) -> Self {
        return self.init(
            xibFiles: xibFiles,
            graph: graph,
            logger: inject(),
            configuration: inject()
        )
    }

    private let xibFiles: Set<FilePath>
    private let graph: SourceGraph
    private let logger: ContextualLogger

    let configuration: Configuration

    required init(xibFiles: Set<FilePath>, graph: SourceGraph, logger: Logger, configuration: Configuration) {
        self.xibFiles = xibFiles
        self.graph = graph
        self.logger = logger.contextualized(with: "index:xib")
        self.configuration = configuration
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
