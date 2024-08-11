import Foundation
import Indexer
import Shared
import SwiftIndexStore
import SystemPackage

public final class GenericProjectDriver {
    struct GenericConfig: Decodable {
        let indexstores: Set<String>
        let plists: Set<String>
        let testTargets: Set<String>
    }

    public static func build(genericProjectConfig: FilePath) throws -> Self {
        guard genericProjectConfig.exists else {
            throw PeripheryError.pathDoesNotExist(path: genericProjectConfig.string)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try Data(contentsOf: genericProjectConfig.url)
        let config = try decoder.decode(GenericConfig.self, from: data)
        let plistPaths = config.plists.mapSet { FilePath.makeAbsolute($0) }
        let indexstorePaths = config.indexstores.mapSet { FilePath.makeAbsolute($0) }

        return self.init(
            indexstorePaths: indexstorePaths,
            plistPaths: plistPaths,
            testTargets: config.testTargets,
            configuration: .shared
        )
    }

    private let indexstorePaths: Set<FilePath>
    private let plistPaths: Set<FilePath>
    private let testTargets: Set<String>
    private let configuration: Configuration

    private init(
        indexstorePaths: Set<FilePath>,
        plistPaths: Set<FilePath>,
        testTargets: Set<String>,
        configuration: Configuration
    ) {
        self.indexstorePaths = indexstorePaths
        self.plistPaths = plistPaths
        self.testTargets = testTargets
        self.configuration = configuration
    }
}

extension GenericProjectDriver: ProjectDriver {
    public func build() throws {}

    public func plan(logger: ContextualLogger) throws -> IndexPlan {
        let excludedTestTargets = configuration.excludeTests ? testTargets : []
        let collector = SourceFileCollector(
            indexStorePaths: Set(configuration.indexStorePath).union(indexstorePaths),
            excludedTestTargets: excludedTestTargets,
            logger: logger
        )
        let sourceFiles = try collector.collect()

        return IndexPlan(
            sourceFiles: sourceFiles,
            plistPaths: plistPaths
        )
    }
}
