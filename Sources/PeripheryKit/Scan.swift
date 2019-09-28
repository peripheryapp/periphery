import Foundation
import PathKit

public final class Scan: Injectable {
    public static func make() -> Self {
        return self.init(configuration: inject(),
                         xcodebuild: inject(),
                         logger: inject())
    }

    private let configuration: Configuration
    private let xcodebuild: Xcodebuild
    private let logger: Logger

    public required init(configuration: Configuration,
                         xcodebuild: Xcodebuild,
                         logger: Logger) {
        self.configuration = configuration
        self.xcodebuild = xcodebuild
        self.logger = logger
    }

    public func perform() throws -> ScanResult {
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

        logger.debug("[version] \(PeripheryVersion)")
        let configYaml = try configuration.asYaml()
        logger.debug("[configuration]\n--- # .periphery.yml\n\(configYaml.trimmed)\n")

        let project: XcodeProjectlike

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Inspecting project configuration...")
        }

        if let workspacePath = configuration.workspace {
            project = try Workspace.make(path: workspacePath)
        } else if let projectPath = configuration.project {
            project = try Project.make(path: projectPath)
        } else {
            throw PeripheryKitError.usageError("Expected --workspace or --project option.")
        }

        // Ensure schemes exist within the project
        let schemes = try project.schemes().filter { configuration.schemes.contains($0.name) }
        let validSchemeNames = Set(schemes.map { $0.name })
        if let scheme = Set(configuration.schemes).subtracting(validSchemeNames).first {
            throw PeripheryKitError.invalidScheme(name: scheme, project: project.path.lastComponent)
        }

        // Ensure targets are part of the project
        let targets = project.targets.filter { configuration.targets.contains($0.name) }
        let missingTargetNames = Set(configuration.targets).subtracting(targets.map { $0.name })

        if let name = missingTargetNames.first {
            throw PeripheryKitError.invalidTarget(name: name, project: project.path.lastComponent)
        }

        try targets.forEach { try $0.identifyModuleName() }
        try TargetSourceFileUniquenessChecker.check(targets: targets)

        let buildLog = try BuildLog.make(project: project, schemes: schemes, targets: targets).get()
        let buildPlan = try BuildPlan.make(buildLog: buildLog, targets: targets)
        let graph = SourceGraph()

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Indexing...")
        }

        try Indexer.perform(buildPlan: buildPlan, graph: graph)

        if configuration.outputFormat.supportsAuxiliaryOutput {
            let asterisk = colorize("*", .boldGreen)
            logger.info("\(asterisk) Analyzing...\n")
        }

        try Analyzer.perform(graph: graph)

        let reducer = RedundantDeclarationReducer(declarations: graph.dereferencedDeclarations)
        let reducedDeclarations = reducer.reduce()

        return ScanResult(declarations: reducedDeclarations, graph: graph)
    }
}
