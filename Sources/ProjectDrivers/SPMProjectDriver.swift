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
                let asterisk = logger.colorize("*", .boldGreen)
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

        // Load package description once and reuse it
        let description = try pkg.load()

        let excludedTestTargets = configuration.excludeTests ? testTargetNames(from: description) : []
        let collector = SourceFileCollector(
            indexStorePaths: indexStorePaths,
            excludedTestTargets: excludedTestTargets,
            logger: logger,
            configuration: configuration
        )
        let sourceFiles = try collector.collect()
        let xibPaths = interfaceBuilderFiles(from: description)

        return IndexPlan(
            sourceFiles: sourceFiles,
            xibPaths: xibPaths
        )
    }

    // MARK: - Private

    private func testTargetNames(from description: PackageDescription) -> Set<String> {
        description.targets.filter(\.isTestTarget).mapSet(\.name)
    }

    private func interfaceBuilderFiles(from description: PackageDescription) -> Set<FilePath> {
        var xibFiles: Set<FilePath> = []

        for target in description.targets {
            let targetPath = pkg.path.appending(target.path)

            guard let resources = target.resources else { continue }

            for resource in resources {
                // Resource.path is always a single file path
                let resourceFilePath = FilePath(resource.path)
                let resourcePath: FilePath = resourceFilePath.isAbsolute
                    ? resourceFilePath
                    : targetPath.appending(resource.path)

                // Check if the resource path exists and is a xib/storyboard file
                guard resourcePath.exists else { continue }
                guard let ext = resourcePath.extension?.lowercased(), ["xib", "storyboard"].contains(ext) else { continue }

                xibFiles.insert(resourcePath)
            }
        }

        return xibFiles
    }
}
