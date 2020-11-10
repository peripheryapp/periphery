import Foundation
import PathKit
import PeripheryKit
import Shared

#if canImport(XcodeSupport)
import XcodeSupport
#endif

public final class Project {
    enum Kind: CustomStringConvertible {
        case xcode
        case spm

        var description: String {
            switch self {
            case .spm:
                return "Swift Package Manager"
            case .xcode:
                return "Xcode"
            }
        }
    }

    static func identify() throws -> Self {
        if (Path.current + "Package.swift").exists {
            return try self.init(kind: .spm)
        }

        return try self.init(kind: .xcode)
    }

    let kind: Kind

    init(kind: Kind) throws {
        self.kind = kind
    }

    func validateEnvironment() throws {
        let logger: Logger = inject()
        let shell = Shell()

        logger.debug(try shell.exec(["swift", "--version"]).trimmed)

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

    func setupGuide() -> SetupGuide {
        switch kind {
        case .xcode:
            #if os(Linux)
            fatalError("Xcode projects are not supported on Linux.")
            #else
            return XcodeProjectSetupGuide.make()
            #endif
        case .spm:
            return SPMProjectSetupGuide.make()
        }
    }
}
