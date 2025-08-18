#if os(macOS)
    import Configuration
    import Foundation
    import Indexer
    import Logger
    import Shared
    import SourceGraph
    import SystemPackage
    import XcodeSupport

    public final class XcodeProjectDriver {
        private let logger: Logger
        private let configuration: Configuration
        private let xcodebuild: Xcodebuild
        private let project: XcodeProjectlike
        private let schemes: Set<String>

        public convenience init(
            projectPath: FilePath,
            configuration: Configuration,
            shell: Shell,
            logger: Logger
        ) throws {
            if configuration.outputFormat.supportsAuxiliaryOutput {
                let asterisk = Logger.colorize("*", .boldGreen)
                logger.info("\(asterisk) Inspecting project...")
            }

            let xcodebuild = Xcodebuild(shell: shell, logger: logger)

            guard !configuration.schemes.isEmpty else {
                throw PeripheryError.usageError("The '--schemes' option is required.")
            }

            try xcodebuild.ensureConfigured()

            let project: XcodeProjectlike = if projectPath.extension == "xcworkspace" {
                try XcodeWorkspace(
                    path: .makeAbsolute(projectPath),
                    xcodebuild: xcodebuild,
                    configuration: configuration,
                    logger: logger,
                    shell: shell
                )
            } else {
                try XcodeProject(
                    path: .makeAbsolute(projectPath),
                    xcodebuild: xcodebuild,
                    shell: shell,
                    logger: logger
                )
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

            self.init(
                logger: logger,
                configuration: configuration,
                xcodebuild: xcodebuild,
                project: project,
                schemes: schemes
            )
        }

        init(
            logger: Logger,
            configuration: Configuration,
            xcodebuild: Xcodebuild,
            project: XcodeProjectlike,
            schemes: Set<String>
        ) {
            self.logger = logger
            self.configuration = configuration
            self.xcodebuild = xcodebuild
            self.project = project
            self.schemes = schemes
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
                    let asterisk = Logger.colorize("*", .boldGreen)
                    logger.info("\(asterisk) Building \(scheme)...")
                }

                try xcodebuild.build(project: project,
                                     scheme: scheme,
                                     allSchemes: Array(schemes),
                                     additionalArguments: configuration.buildArguments)
            }
        }

        public func plan(logger: ContextualLogger) throws -> IndexPlan {
            let indexStorePaths: Set<FilePath> = if !configuration.indexStorePath.isEmpty {
                Set(configuration.indexStorePath)
            } else {
                try [xcodebuild.indexStorePath(project: project, schemes: Array(schemes))]
            }

            let targets = project.targets
            try targets.forEach { try $0.identifyFiles() }
            let excludedTestTargets = configuration.excludeTests ? project.targets.filter(\.isTestTarget).mapSet(\.name) : []
            let collector = SourceFileCollector(
                indexStorePaths: indexStorePaths,
                excludedTestTargets: excludedTestTargets,
                logger: logger,
                configuration: configuration
            )
            let sourceFiles = try collector.collect()
            let infoPlistPaths = targets.flatMapSet { $0.files(kind: .infoPlist) }
            let xibPaths = targets.flatMapSet { $0.files(kind: .interfaceBuilder) }
            let xcDataModelPaths = targets.flatMapSet { $0.files(kind: .xcDataModel) }
            let xcMappingModelPaths = targets.flatMapSet { $0.files(kind: .xcMappingModel) }

            return IndexPlan(
                sourceFiles: sourceFiles,
                plistPaths: infoPlistPaths,
                xibPaths: xibPaths,
                xcDataModelPaths: xcDataModelPaths,
                xcMappingModelPaths: xcMappingModelPaths
            )
        }
    }
#endif
