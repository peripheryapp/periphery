import Foundation
import ProjectDrivers
import Shared
import SystemPackage

final class Project {
    static func identify() throws -> Self {
        let configuration = Configuration.shared

        if let path = configuration.project {
            return self.init(kind: .xcode(projectPath: path))
        } else if let path = configuration.genericProjectConfig {
            return self.init(kind: .generic(genericProjectConfig: path))
        } else if BazelProjectDriver.isSupported && configuration.bazel {
          return self.init(kind: .bazel)
        } else if SPM.isSupported {
            return self.init(kind: .spm)
        }

        throw PeripheryError.usageError("Failed to identify project kind.")
    }

    let kind: ProjectKind

    init(kind: ProjectKind) {
        self.kind = kind
    }

    func driver() throws -> ProjectDriver {
        switch kind {
        case .xcode(let projectPath):
            #if canImport(XcodeSupport)
            return try XcodeProjectDriver.build(projectPath: projectPath)
            #else
            fatalError("Xcode projects are not supported on this platform.")
            #endif
        case .spm:
            return try SPMProjectDriver.build()
        case .bazel:
          return try BazelProjectDriver.build()
        case .generic(let genericProjectConfig):
            return try GenericProjectDriver.build(genericProjectConfig: genericProjectConfig)
        }
    }
}
