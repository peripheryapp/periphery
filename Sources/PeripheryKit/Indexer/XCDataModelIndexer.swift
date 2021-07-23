import Shared
import SystemPackage

public final class XCDataModelIndexer: IndexExcludable {
    public static func make(files: Set<FilePath>, graph: SourceGraph) -> Self {
        return self.init(
            files: files,
            graph: graph,
            logger: inject(),
            configuration: inject()
        )
    }

    private let files: Set<FilePath>
    private let graph: SourceGraph
    private let logger: Logger

    let configuration: Configuration

    required init(files: Set<FilePath>, graph: SourceGraph, logger: Logger, configuration: Configuration) {
        self.files = files
        self.graph = graph
        self.logger = logger
        self.configuration = configuration
    }

    public func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: files)
        excludedFiles.forEach { self.logger.debug("[index:xcdatamodel] Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self = self else { return }

            let elapsed = try Benchmark.measure {
                try XCDataModelParser(path: path)
                    .parse()
                    .forEach { self.graph.add($0) }
            }

            self.logger.debug("[index:xcdatamodel] \(path.string) (\(elapsed)s)")
        }
    }
}
