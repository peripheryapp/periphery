import Foundation
import SystemPackage
import Shared

public final class SPMProjectDriver {
    public static func build() throws -> Self {
        let configuration = Configuration.shared
        let package = try SPM.Package.load()
        let targets: [SPM.Target]

        if !configuration.schemes.isEmpty {
            throw PeripheryError.usageError("The --schemes option has no effect with Swift Package Manager projects.")
        }

        if configuration.targets.isEmpty {
            targets = package.swiftTargets
        } else {
            targets = package.swiftTargets.filter { configuration.targets.contains($0.name) }
            let invalidTargetNames = Set(configuration.targets).subtracting(targets.map { $0.name })

            if !invalidTargetNames.isEmpty {
                throw PeripheryError.invalidTargets(names: invalidTargetNames.sorted(), project: SPM.packageFile)
            }
        }

        return self.init(package: package, targets: targets, configuration: configuration, logger: .init())
    }

    private let package: SPM.Package
    let targets: [SPM.Target]
    private let configuration: Configuration
    private let logger: Logger

    init(package: SPM.Package, targets: [SPM.Target], configuration: Configuration, logger: Logger = .init()) {
        self.package = package
        self.targets = targets
        self.configuration = configuration
        self.logger = logger
    }
}

extension SPMProjectDriver: ProjectDriver {
    public func build() throws {
        if !configuration.skipBuild {
            if configuration.cleanBuild {
                try package.clean()
            }

            try targets.forEach {
                if configuration.outputFormat.supportsAuxiliaryOutput {
                    let asterisk = colorize("*", .boldGreen)
                    logger.info("\(asterisk) Building \($0.name)...")
                }

                try $0.build(additionalArguments: configuration.buildArguments)
            }
        }
    }

    public func index(graph: SourceGraph) throws {
        let sourceFiles = targets.reduce(into: [FilePath: Set<String>]()) { result, target in
            let targetPath = absolutePath(for: target)
            target.sources.forEach { result[targetPath.appending($0), default: []].insert(target.name) }
        }

        let storePaths: [FilePath]

        if !configuration.indexStorePath.isEmpty {
            storePaths = configuration.indexStorePath
        } else {
            storePaths = [FilePath(package.path).appending(".build/debug/index/store")]
        }

        try SwiftIndexer(sourceFiles: sourceFiles, graph: graph, indexStorePaths: storePaths).perform()

        graph.indexingComplete()
    }

    // MARK: - Private

    private func absolutePath(for target: SPM.Target) -> FilePath {
        FilePath(package.path).appending(target.path)
    }
}
