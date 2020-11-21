import Foundation
import PathKit
import Shared

public final class SPMProjectDriver {
    public static func make() throws -> Self {
        let configuration: Configuration = inject()
        let package = try SPM.Package.load()
        let targets: [SPM.Target]

        if !configuration.schemes.isEmpty {
            throw PeripheryError.usageError("The --schemes option has no effect with Swift Package Manager projects.")
        }

        if configuration.targets.isEmpty {
            targets = package.swiftTargets
        } else {
            targets = package.swiftTargets.filter { configuration.targets.contains($0.name) }
        }

        return self.init(package: package, targets: targets, configuration: configuration, logger: inject())
    }

    private let package: SPM.Package
    private var targets: [SPM.Target]
    private let configuration: Configuration
    private let logger: Logger

    init(package: SPM.Package, targets: [SPM.Target], configuration: Configuration, logger: Logger) {
        self.package = package
        self.targets = targets
        self.configuration = configuration
        self.logger = logger
    }

    func setTargets(_ targets: [SPM.Target]) {
        self.targets = targets
    }
}

extension SPMProjectDriver: ProjectDriver {
    public func build() throws {
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

    public func index(graph: SourceGraph) throws {
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

        try SwiftIndexer.make(storePath: storePath, sourceFiles: sourceFiles, graph: graph).perform()
    }
}
