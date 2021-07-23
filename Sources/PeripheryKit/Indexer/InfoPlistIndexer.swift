import Shared
import SystemPackage

public final class InfoPlistIndexer: IndexExcludable {
    public static func make(infoPlistFiles: Set<FilePath>, graph: SourceGraph) -> Self {
        return self.init(
            infoPlistFiles: infoPlistFiles,
            graph: graph,
            logger: inject(),
            configuration: inject()
        )
    }

    private let infoPlistFiles: Set<FilePath>
    private let graph: SourceGraph
    private let logger: Logger

    let configuration: Configuration

    required init(infoPlistFiles: Set<FilePath>, graph: SourceGraph, logger: Logger, configuration: Configuration) {
        self.infoPlistFiles = infoPlistFiles
        self.graph = graph
        self.logger = logger
        self.configuration = configuration
    }

    public func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: infoPlistFiles)
        excludedFiles.forEach { self.logger.debug("[index:infoplist] Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self = self else { return }

            let elapsed = try Benchmark.measure {
                try InfoPlistParser(path: path)
                    .parse()
                    .forEach { self.graph.add($0)  }
            }

            self.logger.debug("[index:infoplist] \(path.string) (\(elapsed)s)")
        }
    }
}
