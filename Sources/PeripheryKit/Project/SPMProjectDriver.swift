import Foundation
import PathKit

final class SPMProjectDriver {
    static func make() throws -> Self {
        let configuration: Configuration = inject()
        let package = try SPM.Package.load()
        let targets: [SPM.Target]

        if configuration.workspace != nil {
            throw PeripheryKitError.usageError("The --workspace option has no effect with Swift Package Manager projects.")
        }

        if configuration.project != nil {
            throw PeripheryKitError.usageError("The --project option has no effect with Swift Package Manager projects.")
        }

        if !configuration.schemes.isEmpty {
            throw PeripheryKitError.usageError("The --schemes option has no effect with Swift Package Manager projects.")
        }

        if configuration.targets.isEmpty {
            targets = package.swiftTargets
        } else {
            targets = package.swiftTargets.filter { configuration.targets.contains($0.name) }
        }

        return self.init(package: package, targets: targets, configuration: configuration, logger: inject())
    }

    private let package: SPM.Package
    private let targets: [SPM.Target]
    private let configuration: Configuration
    private let logger: Logger

    init(package: SPM.Package, targets: [SPM.Target], configuration: Configuration, logger: Logger) {
        self.package = package
        self.targets = targets
        self.configuration = configuration
        self.logger = logger
    }
}

extension SPMProjectDriver: ProjectDriver {
    func build() throws {
        if !configuration.skipBuild {
            try targets.forEach {
                if configuration.outputFormat.supportsAuxiliaryOutput {
                    let asterisk = colorize("*", .boldGreen)
                    logger.info("\(asterisk) Building \($0.name)...")
                }

                try $0.build()
            }
        }
    }

    func index(graph: SourceGraph) throws {
        let sourceFiles = Set(targets.map { target -> [Path] in
            let path = Path(target.path)
            return target.sources.map { path + $0 }
        }.joined())

        let storePath: String

        if let path = configuration.indexStorePath {
            storePath = path
        } else if let env = ProcessInfo.processInfo.environment["BUILD_ROOT"] {
            storePath = (Path(env).absolute().parent().parent() + "Index/DataStore").string
        } else {
            storePath = (Path(package.path) + ".build/debug/index/store").string
        }

        try IndexStoreIndexer.make(storePath: storePath, sourceFiles: sourceFiles, graph: graph).perform()
    }
}
