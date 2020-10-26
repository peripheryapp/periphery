import Foundation
import PathKit

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
            do {
                let xcodebuild: Xcodebuild = inject()
                logger.debug(try xcodebuild.version())
            } catch {
                throw PeripheryKitError.xcodebuildNotConfigured
            }
        default:
            break
        }
    }

    func driver() throws -> ProjectDriver {
        switch kind {
        case .xcode:
            return try XcodeProjectDriver.make()
        case .spm:
            return try SPMProjectDriver.make()
        }
    }

    func setupGuide() -> SetupGuide {
        switch kind {
        case .xcode:
            return XcodeProjectSetupGuide.make()
        case .spm:
            return SPMProjectSetupGuide.make()
        }
    }
}
