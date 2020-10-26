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

        try targets.forEach { try $0.identifyModuleName() }
        try TargetSourceFileUniquenessChecker.check(targets: targets)

        // Ensure schemes exist within the project
        let schemes = try project.schemes().filter { configuration.schemes.contains($0.name) }
        let validSchemeNames = Set(schemes.map { $0.name })

        if let scheme = Set(configuration.schemes).subtracting(validSchemeNames).first {
            throw PeripheryKitError.invalidScheme(name: scheme, project: project.path.lastComponent)
        }

        return self.init(
            configuration: configuration,
            xcodebuild: inject(),
            project: project,
            schemes: schemes,
            targets: targets
        )
    }

    private let configuration: Configuration
    private let xcodebuild: Xcodebuild
    private let project: XcodeProjectlike
    private let schemes: Set<XcodeScheme>
    private var targets: Set<XcodeTarget>

    private var buildPlan: XcodeBuildPlan?

    init(
        configuration: Configuration,
        xcodebuild: Xcodebuild,
        project: XcodeProjectlike,
        schemes: Set<XcodeScheme>,
        targets: Set<XcodeTarget>
    ) {
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

        if configuration.saveBuildLog != nil && configuration.useBuildLog != nil {
            throw PeripheryKitError.usageError("The '--save-build-log' and '--use-build-log' options are mutually exclusive. Please first save the build log with '--save-build-log <key>' and then use it with '--use-build-log <key>'.")
        }

        if configuration.skipBuild {
            throw PeripheryKitError.usageError("The '--skip-build' option is only useable with Swift Package Manager projects.")
        }
    }

    func setTargets(_ targets: Set<XcodeTarget>) {
        self.targets = targets
    }
}

extension XcodeProjectDriver: ProjectDriver {
    func build() throws {
        let buildLog = try XcodeBuildLog.make(project: project, schemes: schemes, targets: targets).get()
        buildPlan = try XcodeBuildPlan.make(buildLog: buildLog, targets: targets)
    }

    func index(graph: SourceGraph) throws {
        guard let buildPlan = buildPlan else { return }

        if configuration.useIndexStore {
            let storePath: String

            if let path = configuration.indexStorePath {
                storePath = path
            } else if let env = ProcessInfo.processInfo.environment["BUILD_ROOT"] {
                storePath = (Path(env).absolute().parent().parent() + "Index/DataStore").string
            } else {
                storePath = try xcodebuild.indexStorePath(project: project)
            }

            let sourceFiles = Set(try targets.map { try $0.sourceFiles().map { $0.path } }.joined())
            try IndexStoreIndexer.make(storePath: storePath, sourceFiles: sourceFiles, graph: graph).perform()
        } else {
            try SourceKitIndexer.make(buildPlan: buildPlan, targets: targets, graph: graph).perform()
        }

        let xibFiles = try Set(targets.map { try $0.xibFiles() }.joined())
        try XibIndexer.make(xibFiles: xibFiles, graph: graph).perform()
    }
}
