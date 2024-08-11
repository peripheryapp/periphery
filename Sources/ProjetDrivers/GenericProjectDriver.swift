import Foundation
import Indexer
import Shared
import SwiftIndexStore
import SystemPackage

public final class GenericProjectDriver {
    struct GenericConfig: Decodable {
        let plistPaths: Set<String>
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
        let plistPaths = config.plistPaths.mapSet { FilePath.makeAbsolute($0) }

        return self.init(
            plistPaths: plistPaths,
            testTargets: config.testTargets,
            configuration: .shared
        )
    }

    private let plistPaths: Set<FilePath>
    private let testTargets: Set<String>
    private let configuration: Configuration

    private init(
        plistPaths: Set<FilePath>,
        testTargets: Set<String>,
        configuration: Configuration
    ) {
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
            indexStorePaths: Set(configuration.indexStorePath),
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
