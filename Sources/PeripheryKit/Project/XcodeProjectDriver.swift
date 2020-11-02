import Foundation
import PathKit

final class XcodeProjectDriver {
    static func make() throws -> Self {
        let configuration: Configuration = inject()
        try validateConfiguration(configuration: configuration)

        let project: XcodeProjectlike

        if let workspacePath = configuration.workspace {
            project = try XcodeWorkspace.make(path: workspacePath)
        } else if let projectPath = configuration.project {
            project = try XcodeProject.make(path: projectPath)
        } else {
            throw PeripheryKitError.usageError("Expected --workspace or --project option.")
        }

        // Ensure targets are part of the project
        let targets = project.targets.filter { configuration.targets.contains($0.name) }
        let missingTargetNames = Set(configuration.targets).subtracting(targets.map { $0.name })

        if let name = missingTargetNames.first {
            throw PeripheryKitError.invalidTarget(name: name, project: project.path.lastComponent)
        }

        try TargetSourceFileUniquenessChecker.check(targets: targets)

        // Ensure schemes exist within the project
        let schemes = try project.schemes().filter { configuration.schemes.contains($0.name) }
        let validSchemeNames = Set(schemes.map { $0.name })

        if let scheme = Set(configuration.schemes).subtracting(validSchemeNames).first {
            throw PeripheryKitError.invalidScheme(name: scheme, project: project.path.lastComponent)
        }

        return self.init(
            logger: inject(),
            configuration: configuration,
            xcodebuild: inject(),
            project: project,
            schemes: schemes,
            targets: targets
        )
    }

    private let logger: Logger
    private let configuration: Configuration
    private let xcodebuild: Xcodebuild
    private let project: XcodeProjectlike
    private let schemes: Set<XcodeScheme>
    private var targets: Set<XcodeTarget>

    init(
        logger: Logger,
        configuration: Configuration,
        xcodebuild: Xcodebuild,
        project: XcodeProjectlike,
        schemes: Set<XcodeScheme>,
        targets: Set<XcodeTarget>
    ) {
        self.logger = logger
        self.configuration = configuration
        self.xcodebuild = xcodebuild
        self.project = project
        self.schemes = schemes
        self.targets = targets
    }

    // MARK: - Private

    private static func validateConfiguration(configuration: Configuration) throws {
        guard configuration.workspace != nil || configuration.project != nil else {
            let message = "You must supply either the --workspace or --project option. If your project uses an .xcworkspace to integrate multiple projects, then supply the --workspace option. Otherwise, supply the --project option."
            throw PeripheryKitError.usageError(message)
        }

        if configuration.workspace != nil && configuration.project != nil {
            let message = "You must supply either the --workspace or --project option, not both. If your project uses an .xcworkspace to integrate multiple projects, then supply the --workspace option. Otherwise, supply the --project option."
            throw PeripheryKitError.usageError(message)
        }

        guard !configuration.schemes.isEmpty else {
            throw PeripheryKitError.usageError("The '--schemes' option is required.")
        }

        guard !configuration.targets.isEmpty else {
            throw PeripheryKitError.usageError("The '--targets' option is required.")
        }
    }

    func setTargets(_ targets: Set<XcodeTarget>) {
        self.targets = targets
    }
}

extension XcodeProjectDriver: ProjectDriver {
    func build() throws {
        // Ensure test targets are built by chosen schemes
        let testTargetNames = targets.filter { $0.isTestTarget }.map { $0.name }

        if !testTargetNames.isEmpty {
            let allTestTargets = try schemes.flatMap { try $0.testTargets() }
            let missingTestTargets = Set(testTargetNames).subtracting(allTestTargets)

            if let name = missingTestTargets.first {
                throw PeripheryKitError.testTargetNotBuildable(name: name)
            }
        }

        guard  !configuration.skipBuild else { return }

        for scheme in schemes {
            if configuration.outputFormat.supportsAuxiliaryOutput {
                let asterisk = colorize("*", .boldGreen)
                logger.info("\(asterisk) Building \(scheme.name)...")
            }

            let buildForTesting = !Set(try scheme.testTargets()).isDisjoint(with: testTargetNames)
            try xcodebuild.build(project: project,
                                 scheme: scheme.name,
                                 additionalArguments: configuration.xcargs,
                                 buildForTesting: buildForTesting)
        }
    }

    func index(graph: SourceGraph) throws {
        let storePath: String

        if let path = configuration.indexStorePath {
            storePath = path
        } else if let env = ProcessInfo.processInfo.environment["BUILD_ROOT"] {
            storePath = (Path(env).absolute().parent().parent() + "Index/DataStore").string
        } else {
            storePath = try xcodebuild.indexStorePath(project: project)
        }

        let sourceFiles = Set(try targets.map { try $0.sourceFiles() }.joined())
        try SwiftIndexer.make(storePath: storePath, sourceFiles: sourceFiles, graph: graph).perform()

        let xibFiles = try Set(targets.map { try $0.xibFiles() }.joined())
        try XibIndexer.make(xibFiles: xibFiles, graph: graph).perform()
    }
}
