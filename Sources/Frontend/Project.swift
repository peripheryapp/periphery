import Foundation
import PeripheryKit
import Shared
import SystemPackage

#if canImport(XcodeSupport)
import XcodeSupport
#endif

final class Project {
    static func identify() -> Self {
        let configuration = Configuration.shared

        if configuration.workspace != nil || configuration.project != nil {
            return self.init(kind: .xcode)
        } else if !configuration.fileTargetsPath.isEmpty {
            return self.init(kind: .generic)
        } else if SPM.isSupported {
            return self.init(kind: .spm)
        }

        return self.init(kind: .xcode)
    }

    let kind: ProjectKind

    init(kind: ProjectKind) {
        self.kind = kind
    }

    func validateEnvironment() throws {
        let logger = Logger()

        logger.debug(SwiftVersion.current.fullVersion)
        try SwiftVersion.current.validateVersion()

        switch kind {
        case .xcode:
            #if canImport(XcodeSupport)
            do {
                let xcodebuild = Xcodebuild()
                logger.debug(try xcodebuild.version())
            } catch {
                throw PeripheryError.xcodebuildNotConfigured
            }
            #else
            fatalError("Xcode projects are not supported on this platform.")
            #endif
        default:
            break
        }
    }

    func driver() throws -> ProjectDriver {
        switch kind {
        case .xcode:
            #if canImport(XcodeSupport)
            return try XcodeProjectDriver.build()
            #else
            fatalError("Xcode projects are not supported on this platform.")
            #endif
        case .spm:
            return try SPMProjectDriver.build()
        case .generic:
            return try GenericProjectDriver.build()
        }
    }
}
