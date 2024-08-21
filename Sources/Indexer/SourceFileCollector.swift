import Foundation
import Shared
import SourceGraph
import SwiftIndexStore
import SystemPackage
import Utils
import Configuration

public struct SourceFileCollector {
    private let indexStorePaths: Set<FilePath>
    private let excludedTestTargets: Set<String>
    private let logger: ContextualLogger
    private let configuration: Configuration

    public init(
        indexStorePaths: Set<FilePath>,
        excludedTestTargets: Set<String>,
        logger: ContextualLogger,
        configuration: Configuration = .shared
    ) {
        self.indexStorePaths = indexStorePaths
        self.excludedTestTargets = excludedTestTargets
        self.logger = logger
        self.configuration = configuration
    }

    public func collect() throws -> [SourceFile: [IndexUnit]] {
        let excludedTargets = excludedTestTargets.union(configuration.excludeTargets)
        let currentFilePath = FilePath.current

        return try JobPool(jobs: Array(indexStorePaths))
            .flatMap { indexStorePath in
                logger.debug("Reading \(indexStorePath)")
                let indexStore = try IndexStore.open(store: URL(fileURLWithPath: indexStorePath.string), lib: .open())
                let units = indexStore.units(includeSystem: false)

                return try units.compactMap { unit -> (FilePath, IndexStore, IndexStoreUnit, String?)? in
                    guard let filePath = try indexStore.mainFilePath(for: unit), !filePath.isEmpty else {
                        return nil
                    }

                    let file = FilePath.makeAbsolute(filePath, relativeTo: currentFilePath)

                    if !isExcluded(file) {
                        guard file.exists else {
                            throw PeripheryError.pathDoesNotExist(path: file.string)
                        }

                        let module = try indexStore.moduleName(for: unit)
                        if let module, excludedTargets.contains(module) {
                            return nil
                        }

                        return (file, indexStore, unit, module)
                    }

                    return nil
                }
            }
            .reduce(into: [FilePath: [(IndexStore, IndexStoreUnit, String?)]]()) { result, tuple in
                let (file, indexStore, unit, module) = tuple
                result[file, default: []].append((indexStore, unit, module))
            }
            .reduce(into: [SourceFile: [IndexUnit]]()) { result, pair in
                let (file, tuples) = pair
                let modules = tuples.compactMapSet { $0.2 }
                let sourceFile = SourceFile(path: file, modules: modules)
                let units = tuples.map { IndexUnit(store: $0.0, unit: $0.1) }
                result[sourceFile] = units
            }
    }

    // MARK: - Private

    private func isExcluded(_ file: FilePath) -> Bool {
        configuration.indexExcludeMatchers.anyMatch(filename: file.string)
    }
}
