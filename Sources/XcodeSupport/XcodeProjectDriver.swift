import Foundation
import SystemPackage
import PeripheryKit
import Shared

public final class XcodeProjectDriver {
    public static func build() throws -> Self {
        let configuration = Configuration.shared
        try validateConfiguration(configuration: configuration)

        let project: XcodeProjectlike

        if let workspacePath = configuration.workspace {
            project = try XcodeWorkspace(path: .makeAbsolute(workspacePath))
        } else if let projectPath = configuration.project {
            project = try XcodeProject(path: .makeAbsolute(projectPath))
        } else {
            throw PeripheryError.usageError("Expected --workspace or --project option.")
        }

        // Ensure targets are part of the project
        var invalidTargetNames: [String] = []

        var targets: Set<XcodeTarget> = []
        var packageTargets: [SPM.Package: Set<SPM.Target>] = [:]

        for targetName in configuration.targets {
            if let target = project.targets.first(where: { $0.name == targetName }) {
                targets.insert(target)
            } else {
                let parts = targetName.split(separator: ".", maxSplits: 1)

                if let packageName = parts.first,
                   let targetName = parts.last,
                   let package = project.packageTargets.keys.first(where: { $0.name == packageName }),
                   let target = project.packageTargets[package]?.first(where: { $0.name == targetName })
                {
                    packageTargets[package, default: []].insert(target)
                } else {
                    invalidTargetNames.append(targetName)
                }
            }
        }

        if !invalidTargetNames.isEmpty {
            throw PeripheryError.invalidTargets(names: invalidTargetNames.sorted(), project: project.path.lastComponent?.string ?? "")
        }

        // Ensure schemes exist within the project
        let schemes = try project.schemes().filter { configuration.schemes.contains($0) }
        let validSchemeNames = schemes.mapSet { $0 }

        if let scheme = Set(configuration.schemes).subtracting(validSchemeNames).first {
            throw PeripheryError.invalidScheme(name: scheme, project: project.path.lastComponent?.string ?? "")
        }

        return self.init(
            project: project,
            schemes: schemes,
            targets: targets,
            packageTargets: packageTargets
        )
    }

    private let logger: Logger
    private let configuration: Configuration
    private let xcodebuild: Xcodebuild
    private let project: XcodeProjectlike
    private let schemes: Set<String>
    private let targets: Set<XcodeTarget>
    private let packageTargets: [SPM.Package: Set<SPM.Target>]

    init(
        logger: Logger = .init(),
        configuration: Configuration = .shared,
        xcodebuild: Xcodebuild = .init(),
        project: XcodeProjectlike,
        schemes: Set<String>,
        targets: Set<XcodeTarget>,
        packageTargets: [SPM.Package: Set<SPM.Target>]
    ) {
        self.logger = logger
        self.configuration = configuration
        self.xcodebuild = xcodebuild
        self.project = project
        self.schemes = schemes
        self.targets = targets
        self.packageTargets = packageTargets
    }

    // MARK: - Private

    private static func validateConfiguration(configuration: Configuration) throws {
        guard configuration.workspace != nil || configuration.project != nil else {
            let message = "You must supply either the --workspace or --project option. If your project uses an .xcworkspace to integrate multiple projects, then supply the --workspace option. Otherwise, supply the --project option."
            throw PeripheryError.usageError(message)
        }

        if configuration.workspace != nil && configuration.project != nil {
            let message = "You must supply either the --workspace or --project option, not both. If your project uses an .xcworkspace to integrate multiple projects, then supply the --workspace option. Otherwise, supply the --project option."
            throw PeripheryError.usageError(message)
        }

        guard !configuration.schemes.isEmpty else {
            throw PeripheryError.usageError("The '--schemes' option is required.")
        }

        guard !configuration.targets.isEmpty else {
            throw PeripheryError.usageError("The '--targets' option is required.")
        }
    }
}

extension XcodeProjectDriver: ProjectDriver {
    public func build() throws {
        // Copy target triples to the targets. The triple is used by the indexer to ignore index store units built for
        // other architectures/platforms.
        let targetTriples = try xcodebuild.buildSettings(targets: targets)
            .mapDict { action in
                (action.target, try action.makeTargetTriple())
            }

        for target in targets {
            if let triple = targetTriples[target.name] {
                target.triple = triple
            }
        }

        guard  !configuration.skipBuild else { return }

        if configuration.cleanBuild {
            try xcodebuild.removeDerivedData(for: project, allSchemes: Array(schemes))
        }

        for scheme in schemes {
            if configuration.outputFormat.supportsAuxiliaryOutput {
                let asterisk = colorize("*", .boldGreen)
                logger.info("\(asterisk) Building \(scheme)...")
            }

            let containsXcodeTestTargets = targets.contains(where: \.isTestTarget)
            let containsPackageTestTargets = packageTargets.values.contains { $0.contains(where: \.isTestTarget) }
            let buildForTesting = containsXcodeTestTargets || containsPackageTestTargets
            try xcodebuild.build(project: project,
                                 scheme: scheme,
                                 allSchemes: Array(schemes),
                                 additionalArguments: configuration.buildArguments,
                                 buildForTesting: buildForTesting)
        }
    }

    public func index(graph: SourceGraph) throws {
        let storePaths: [FilePath]

        if !configuration.indexStorePath.isEmpty {
            storePaths = configuration.indexStorePath
        } else {
            storePaths = [try xcodebuild.indexStorePath(project: project, schemes: Array(schemes))]
        }

        try targets.forEach { try $0.identifyFiles() }

        var sourceFiles: [FilePath: Set<IndexTarget>] = [:]

        for target in targets {
            target.files(kind: .swift).forEach {
                let indexTarget = IndexTarget(name: target.name, triple: target.triple)
                sourceFiles[$0, default: []].insert(indexTarget)
            }
        }

        for (package, targets) in packageTargets {
            let packageRoot = FilePath(package.path)

            for target in targets {
                target.sourcePaths.forEach {
                    let absolutePath = packageRoot.pushing($0)
                    let indexTarget = IndexTarget(name: target.name)
                    sourceFiles[absolutePath, default: []].insert(indexTarget) }
            }
        }

        try SwiftIndexer(sourceFiles: sourceFiles, graph: graph, indexStorePaths: storePaths).perform()

        let xibFiles = targets.flatMapSet { $0.files(kind: .interfaceBuilder) }
        try XibIndexer(xibFiles: xibFiles, graph: graph).perform()

        let xcDataModelFiles = targets.flatMapSet { $0.files(kind: .xcDataModel) }
        try XCDataModelIndexer(files: xcDataModelFiles, graph: graph).perform()

        let xcMappingModelFiles = targets.flatMapSet { $0.files(kind: .xcMappingModel) }
        try XCMappingModelIndexer(files: xcMappingModelFiles, graph: graph).perform()

        let infoPlistFiles = targets.flatMapSet { $0.files(kind: .infoPlist) }
        try InfoPlistIndexer(infoPlistFiles: infoPlistFiles, graph: graph).perform()

        graph.indexingComplete()
    }
}
