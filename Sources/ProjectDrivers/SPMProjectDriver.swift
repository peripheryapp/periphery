import Foundation
import Indexer
import Shared
import SwiftIndexStore
import SystemPackage
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

    public func plan(logger: ContextualLogger) throws -> IndexPlan {
        let indexStorePaths: Set<FilePath>

        if !configuration.indexStorePath.isEmpty {
            indexStorePaths = Set(configuration.indexStorePath)
        } else {
            indexStorePaths = [pkg.path.appending(".build/debug/index/store")]
        }

        let excludedTestTargets = configuration.excludeTests ? try pkg.testTargetNames() : []
        let collector = SourceFileCollector(
            indexStorePaths: indexStorePaths,
            excludedTestTargets: excludedTestTargets,
            logger: logger
        )
        let sourceFiles = try collector.collect()

        return IndexPlan(sourceFiles: sourceFiles)
    }
}
