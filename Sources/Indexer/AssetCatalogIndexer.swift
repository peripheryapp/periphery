import Configuration
import Logger
import Shared
import SourceGraph
import SystemPackage

final class AssetCatalogIndexer: Indexer {
    private let assetCatalogs: Set<FilePath>
    private let graph: SourceGraphMutex
    private let logger: ContextualLogger

    required init(assetCatalogs: Set<FilePath>, graph: SourceGraphMutex, logger: ContextualLogger, configuration: Configuration) {
        self.assetCatalogs = assetCatalogs
        self.graph = graph
        self.logger = logger.contextualized(with: "asset-catalog")
        super.init(configuration: configuration)
    }

    func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: assetCatalogs)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] assetCatalog in
            guard let self else { return }

            let elapsed = Benchmark.measure {
                let imageAssets = AssetCatalogParser(path: assetCatalog).parse()
                self.graph.withLock { graph in
                    imageAssets.forEach { graph.addImageAsset($0) }
                }
            }

            logger.debug("\(assetCatalog.string) (\(elapsed)s)")
        }
    }
}
