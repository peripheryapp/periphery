import Configuration
import Logger
import Shared
import SourceGraph
import SystemPackage

final class XCStringsIndexer: Indexer {
    enum XCStringsError: Error {
        case failedToParse(path: FilePath, underlyingError: Error)
    }

    private let files: Set<FilePath>
    private let graph: SynchronizedSourceGraph
    private let logger: ContextualLogger

    required init(files: Set<FilePath>, graph: SynchronizedSourceGraph, logger: ContextualLogger, configuration: Configuration) {
        self.files = files
        self.graph = graph
        self.logger = logger.contextualized(with: "xcstrings")
        super.init(configuration: configuration)
    }

    func perform() throws {
        let (includedFiles, excludedFiles) = filterIndexExcluded(from: files)
        excludedFiles.forEach { self.logger.debug("Excluding \($0.string)") }

        try JobPool(jobs: Array(includedFiles)).forEach { [weak self] path in
            guard let self else { return }

            let elapsed = try Benchmark.measure {
                do {
                    let keys = try XCStringsParser(path: path).parse()
                    let sourceFile = SourceFile(path: path, modules: [])

                    for key in keys {
                        let location = Location(file: sourceFile, line: 1, column: 1)
                        let declaration = Declaration(
                            kind: .localizedString,
                            usrs: ["xcstrings:\(path.string):\(key)"],
                            location: location
                        )
                        declaration.name = key

                        self.graph.withLock {
                            self.graph.addWithoutLock(declaration)
                        }
                    }
                } catch {
                    throw XCStringsError.failedToParse(path: path, underlyingError: error)
                }
            }

            logger.debug("\(path.string) (\(elapsed)s)")
        }
    }
}
