import Configuration
import Foundation
import Indexer
import Logger
import Shared
import SwiftIndexStore
import SystemPackage

final class GenericProjectDriver {
    struct GenericConfig: Decodable {
        let indexstores: Set<String>
        let plists: Set<String>
        let xibs: Set<String>
        let xcdatamodels: Set<String>
        let xcmappingmodels: Set<String>
        let testTargets: Set<String>
    }

    private let indexstorePaths: Set<FilePath>
    private let plistPaths: Set<FilePath>
    private let xibPaths: Set<FilePath>
    private let xcDataModelsPaths: Set<FilePath>
    private let xcMappingModelsPaths: Set<FilePath>
    private let testTargets: Set<String>
    private let configuration: Configuration

    convenience init(genericProjectConfig: FilePath, configuration: Configuration) throws {
        guard genericProjectConfig.exists else {
            throw PeripheryError.pathDoesNotExist(path: genericProjectConfig.string)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try Data(contentsOf: genericProjectConfig.url)
        let config = try decoder.decode(GenericConfig.self, from: data)
        let plistPaths = config.plists.mapSet { FilePath.makeAbsolute($0) }
        let xibPaths = config.xibs.mapSet { FilePath.makeAbsolute($0) }
        let xcDataModelPaths = config.xcdatamodels.mapSet { FilePath.makeAbsolute($0) }
        let xcMappingModelPaths = config.xcmappingmodels.mapSet { FilePath.makeAbsolute($0) }
        let indexstorePaths = config.indexstores.mapSet { FilePath.makeAbsolute($0) }

        self.init(
            indexstorePaths: indexstorePaths,
            plistPaths: plistPaths,
            xibPaths: xibPaths,
            xcDataModelsPaths: xcDataModelPaths,
            xcMappingModelsPaths: xcMappingModelPaths,
            testTargets: config.testTargets,
            configuration: configuration
        )
    }

    private init(
        indexstorePaths: Set<FilePath>,
        plistPaths: Set<FilePath>,
        xibPaths: Set<FilePath>,
        xcDataModelsPaths: Set<FilePath>,
        xcMappingModelsPaths: Set<FilePath>,
        testTargets: Set<String>,
        configuration: Configuration
    ) {
        self.indexstorePaths = indexstorePaths
        self.plistPaths = plistPaths
        self.xibPaths = xibPaths
        self.xcDataModelsPaths = xcDataModelsPaths
        self.xcMappingModelsPaths = xcMappingModelsPaths
        self.testTargets = testTargets
        self.configuration = configuration
    }
}

extension GenericProjectDriver: ProjectDriver {
    public func plan(logger: ContextualLogger) throws -> IndexPlan {
        let excludedTestTargets = configuration.excludeTests ? testTargets : []
        let collector = SourceFileCollector(
            indexStorePaths: Set(configuration.indexStorePath).union(indexstorePaths),
            excludedTestTargets: excludedTestTargets,
            logger: logger,
            configuration: configuration
        )
        let sourceFiles = try collector.collect()

        return IndexPlan(
            sourceFiles: sourceFiles,
            plistPaths: plistPaths,
            xibPaths: xibPaths,
            xcDataModelPaths: xcDataModelsPaths,
            xcMappingModelPaths: xcMappingModelsPaths
        )
    }
}
