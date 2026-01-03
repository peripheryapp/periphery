import Configuration
import Foundation
import Logger
import ProjectDrivers
import Shared
import SystemPackage

final class Project {
    let kind: ProjectKind

    private let configuration: Configuration
    private let shell: Shell
    private let logger: Logger

    convenience init(
        configuration: Configuration,
        shell: Shell,
        logger: Logger
    ) throws {
        var kind: ProjectKind?

        if let path = configuration.project {
            kind = .xcode(projectPath: path)
        } else if let path = configuration.genericProjectConfig {
            kind = .generic(genericProjectConfig: path)
        } else if BazelProjectDriver.isSupported, configuration.bazel {
            kind = .bazel
        } else if SPM.isSupported {
            kind = .spm
        }

        guard let kind else {
            throw PeripheryError.usageError("Failed to identify project in the current directory. For Xcode projects use the '--project' option, and for SPM projects change to the directory containing the Package.swift.")
        }

        self.init(kind: kind, configuration: configuration, shell: shell, logger: logger)
    }

    init(
        kind: ProjectKind,
        configuration: Configuration,
        shell: Shell,
        logger: Logger
    ) {
        self.kind = kind
        self.configuration = configuration
        self.shell = shell
        self.logger = logger
    }

    func driver() throws -> ProjectDriver {
        switch kind {
        case let .xcode(projectPath):
            #if canImport(XcodeSupport)
                return try XcodeProjectDriver(
                    projectPath: projectPath,
                    configuration: configuration,
                    shell: shell,
                    logger: logger
                )
            #else
                fatalError("Xcode projects are not supported on this platform.")
            #endif
        case .spm:
            return try SPMProjectDriver(configuration: configuration, shell: shell, logger: logger)
        case .bazel:
            return BazelProjectDriver(
                configuration: configuration,
                shell: shell,
                logger: logger
            )
        case let .generic(genericProjectConfig):
            return try GenericProjectDriver(
                genericProjectConfig: genericProjectConfig,
                configuration: configuration
            )
        }
    }
}
