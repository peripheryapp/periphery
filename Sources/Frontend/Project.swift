import Foundation
import SystemPackage
import PeripheryKit
import Shared

#if canImport(XcodeSupport)
import XcodeSupport
#endif

final class Project {
    static func identify() -> Self {
        let configuration: Configuration = inject()

        if configuration.workspace != nil || configuration.project != nil {
            return self.init(kind: .xcode)
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
        let logger: Logger = inject()

        logger.debug(SwiftVersion.current.fullVersion)
        try SwiftVersion.current.validateVersion()

        switch kind {
        case .xcode:
            #if os(Linux)
            fatalError("Xcode projects are not supported on Linux.")
            #else
            do {
                let xcodebuild: Xcodebuild = inject()
                logger.debug(try xcodebuild.version())
            } catch {
                throw PeripheryError.xcodebuildNotConfigured
            }
            #endif
        default:
            break
        }
    }

    func driver() throws -> ProjectDriver {
        switch kind {
        case .xcode:
            #if os(Linux)
            fatalError("Xcode projects are not supported on Linux.")
            #else
            return try XcodeProjectDriver.make()
            #endif
        case .spm:
            return try SPMProjectDriver.make()
        }
    }
}
