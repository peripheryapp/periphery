import Foundation
import SwiftIndexStore
import SystemPackage
import Shared
import SourceGraph
import Indexer

public final class SPMProjectDriver {
    public static func build() throws -> Self {
        let configuration = Configuration.shared

        if !configuration.schemes.isEmpty {
            throw PeripheryError.usageError("The --schemes option has no effect with Swift Package Manager projects.")
        }

        let pkg = SPM.Package()
        return self.init(pkg: pkg, configuration: configuration, logger: .init())
    }

    private let pkg: SPM.Package
    private let configuration: Configuration
    private let logger: Logger

    init(pkg: SPM.Package, configuration: Configuration, logger: Logger = .init()) {
        self.pkg = pkg
        self.configuration = configuration
        self.logger = logger
    }
}

extension SPMProjectDriver: ProjectDriver {
    public func build() throws {
        if !configuration.skipBuild {
            if configuration.cleanBuild {
                try pkg.clean()
            }

            if configuration.outputFormat.supportsAuxiliaryOutput {
                let asterisk = colorize("*", .boldGreen)
                logger.info("\(asterisk) Building...")
            }

            try pkg.build(additionalArguments: configuration.buildArguments)
        }
    }

    public func collect(logger: ContextualLogger) throws -> [SourceFile : [IndexUnit]] {
        let storePaths: [FilePath]

        if !configuration.indexStorePath.isEmpty {
            storePaths = configuration.indexStorePath
        } else {
            storePaths = [pkg.path.appending(".build/debug/index/store")]
        }

        let excludedTestTargets = configuration.excludeTests ? try pkg.testTargetNames() : []

        return try SourceFileCollector(
            indexStorePaths: storePaths,
            excludedTestTargets: excludedTestTargets,
            logger: logger
        ).collect()
    }

    public func index(
        sourceFiles: [SourceFile: [IndexUnit]],
        graph: SourceGraph,
        logger: ContextualLogger
    ) throws {
        try SwiftIndexer(
            sourceFiles: sourceFiles,
            graph: graph,
            logger: logger
        ).perform()

        graph.indexingComplete()
    }
}
