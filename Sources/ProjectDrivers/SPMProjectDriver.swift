import Configuration
import Foundation
import Indexer
import Logger
import Shared
import SwiftIndexStore
import SystemPackage

public final class SPMProjectDriver {
    private let pkg: SPM.Package
    private let configuration: Configuration
    private let logger: Logger

    public convenience init(configuration: Configuration, shell: Shell, logger: Logger) throws {
        if !configuration.schemes.isEmpty {
            throw PeripheryError.usageError("The --schemes option has no effect with Swift Package Manager projects.")
        }

        let pkg = SPM.Package(configuration: configuration, shell: shell, logger: logger)
        self.init(pkg: pkg, configuration: configuration, logger: logger)
    }

    init(pkg: SPM.Package, configuration: Configuration, logger: Logger) {
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
                let asterisk = Logger.colorize("*", .boldGreen)
                logger.info("\(asterisk) Building...")
            }

            try pkg.build(additionalArguments: configuration.buildArguments)
        }
    }

    public func plan(logger: ContextualLogger) throws -> IndexPlan {
        let indexStorePaths: Set<FilePath> = if !configuration.indexStorePath.isEmpty {
            Set(configuration.indexStorePath)
        } else {
            [pkg.path.appending(".build/debug/index/store")]
        }

        let excludedTestTargets = configuration.excludeTests ? try pkg.testTargetNames() : []
        let collector = SourceFileCollector(
            indexStorePaths: indexStorePaths,
            excludedTestTargets: excludedTestTargets,
            logger: logger,
            configuration: configuration
        )
        let sourceFiles = try collector.collect()

        return IndexPlan(sourceFiles: sourceFiles)
    }
}
