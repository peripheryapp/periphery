import Foundation
import SystemPackage
import PeripheryKit
import Shared
import SourceGrap

public final class XcodeProjectDriver {
    public static func build() throws -> Self {
        let configuration = Configuration.shared
        try validateConfiguration(configuration: configuration)

        guard let projectPath = configuration.project else {
            throw PeripheryError.usageError("Expected --project option.")
        }

        let project: XcodeProjectlike

        if projectPath.hasSuffix("xcworkspace") {
            project = try XcodeWorkspace(path: .makeAbsolute(projectPath))
        } else {
            project = try XcodeProject(path: .makeAbsolute(projectPath))
        }

        let schemes: Set<String>

        if configuration.skipSchemesValidation {
            schemes = Set(configuration.schemes)
        } else {
            // Ensure schemes exist within the project
            schemes = try project.schemes(
                additionalArguments: configuration.xcodeListArguments
            ).filter { configuration.schemes.contains($0) }
            let validSchemeNames = schemes.mapSet { $0 }

            if let scheme = Set(configuration.schemes).subtracting(validSchemeNames).first {
                throw PeripheryError.invalidScheme(name: scheme, project: project.path.lastComponent?.string ?? "")
            }
        }

        return self.init(
            project: project,
            schemes: schemes
        )
    }

    private let logger: Logger
    private let configuration: Configuration
    private let xcodebuild: Xcodebuild
    private let project: XcodeProjectlike
    private let schemes: Set<String>

    init(
        logger: Logger = .init(),
        configuration: Configuration = .shared,
        xcodebuild: Xcodebuild = .init(),
        project: XcodeProjectlike,
        schemes: Set<String>
    ) {
        self.logger = logger
        self.configuration = configuration
        self.xcodebuild = xcodebuild
        self.project = project
        self.schemes = schemes
    }

    // MARK: - Private

    private static func validateConfiguration(configuration: Configuration) throws {
        guard configuration.project != nil else {
            let message = "You must supply the --project option."
            throw PeripheryError.usageError(message)
        }

        guard !configuration.schemes.isEmpty else {
            throw PeripheryError.usageError("The '--schemes' option is required.")
        }
    }
}

extension XcodeProjectDriver: ProjectDriver {
    public func build() throws {
        guard !configuration.skipBuild else { return }

        if configuration.cleanBuild {
            try xcodebuild.removeDerivedData(for: project, allSchemes: Array(schemes))
        }

        for scheme in schemes {
            if configuration.outputFormat.supportsAuxiliaryOutput {
                let asterisk = colorize("*", .boldGreen)
                logger.info("\(asterisk) Building \(scheme)...")
            }

            try xcodebuild.build(project: project,
                                 scheme: scheme,
                                 allSchemes: Array(schemes),
                                 additionalArguments: configuration.buildArguments,
                                 buildForTesting: true) // TODO: auto detect? configurable?
        }
    }

    public func collect(logger: ContextualLogger) throws -> [SourceFile : [IndexUnit]] {
        let storePaths: [FilePath]

        if !configuration.indexStorePath.isEmpty {
            storePaths = configuration.indexStorePath
        } else {
            storePaths = [try xcodebuild.indexStorePath(project: project, schemes: Array(schemes))]
        }

        return try SourceFileCollector(
            indexStorePaths: storePaths,
            logger: logger
        ).collect()
    }

    public func index(
        sourceFiles: [SourceFile: [IndexUnit]],
        graph: SourceGraph,
        logger: ContextualLogger
    ) throws {
        try SwiftIndexer(
            sourceFiles: sourceFiles,
            graph: graph,
            logger: logger
        ).perform()

        let modules = sourceFiles.keys.flatMapSet { $0.modules }
        let targets = project.targets.filter { modules.contains($0.name) }
        try targets.forEach { try $0.identifyFiles() }

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
