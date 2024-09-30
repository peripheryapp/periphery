import Configuration
import Foundation
import Logger
import Shared
import SystemPackage

public final class Project {
    let kind: ProjectKind

    private let configuration: Configuration
    private let shell: Shell
    private let logger: Logger

    public convenience init(
        configuration: Configuration,
        shell: Shell,
        logger: Logger
    ) throws {
        try self.init(
            kind: Self.detectKind(configuration: configuration),
            configuration: configuration,
            shell: shell,
            logger: logger
        )
    }

    public init(configuration: Configuration) throws {
        self.configuration = configuration
        logger = Logger()
        shell = Shell(logger: logger)
        kind = try Self.detectKind(configuration: configuration)
    }

    public init(
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

    static func detectKind(configuration: Configuration) throws -> ProjectKind {
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

        return kind
    }

    public func driver() throws -> ProjectDriver {
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
            return try BazelProjectDriver.build(
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
