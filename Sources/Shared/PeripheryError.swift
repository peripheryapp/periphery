import Foundation
import SystemPackage

public enum PeripheryError: Error, LocalizedError, CustomStringConvertible {
    case shellCommandFailed(cmd: String, args: [String], status: Int32, output: String)
    case shellOutputEncodingFailed(cmd: String, args: [String], encoding: String.Encoding)
    case usageError(String)
    case underlyingError(Error)
    case invalidScheme(name: String, project: String)
    case sourceGraphIntegrityError(message: String)
    case guidedSetupError(message: String)
    case updateCheckError(message: String)
    case xcodebuildNotConfigured
    case pathDoesNotExist(path: String)
    case foundIssues(count: Int)
    case packageError(message: String)
    case swiftVersionParseError(fullVersion: String)
    case swiftVersionUnsupportedError(version: String, minimumVersion: String)
    case jsonDeserializationError(error: Error, json: String)
    case indexStoreNotFound(derivedDataPath: String)

    public var errorDescription: String? {
        switch self {
        case let .shellCommandFailed(cmd, args, status, output):
            let joinedArgs = args.joined(separator: " ")
            return "Shell command '\(cmd) \(joinedArgs)' returned exit status '\(status)':\n\(output)"
        case let .shellOutputEncodingFailed(cmd, args, encoding):
            let joinedArgs = args.joined(separator: " ")
            return "Shell command '\(cmd) \(joinedArgs)' output encoding to \(encoding) failed."
        case let .usageError(message):
            return message
        case let .underlyingError(error):
            return describe(error)
        case let .invalidScheme(name, project):
            return "Scheme '\(name)' does not exist in '\(project)'."
        case .sourceGraphIntegrityError(let message):
            return message
        case .guidedSetupError(let message):
            return "\(message). Please refer to the documentation for instructions on configuring Periphery manually - https://github.com/peripheryapp/periphery/blob/master/README.md"
        case .updateCheckError(let message):
            return message
        case .xcodebuildNotConfigured:
            return "Xcode is not configured for command-line use. Please run 'sudo xcode-select -s /Applications/Xcode.app'."
        case .pathDoesNotExist(let path):
            return "No such file or directory: \(path)."
        case .foundIssues(let count):
            return "Found \(count) \(count > 1 ? "issues" : "issue")."
        case .packageError(let message):
            return message
        case .swiftVersionParseError(let fullVersion):
            return "Failed to parse Swift version from: \(fullVersion)"
        case let .swiftVersionUnsupportedError(version, minimumVersion):
            return "This version of Periphery only supports Swift >= \(minimumVersion), you're using \(version)."
        case let .jsonDeserializationError(error, json):
            return "JSON deserialization failed: \(describe(error))\nJSON:\n\(json)"
        case let .indexStoreNotFound(derivedDataPath):
            return "Failed to find index datastore at path: \(derivedDataPath)"
        }
    }

    public var description: String {
        return errorDescription!
    }

    // MARK: - Private

    private func describe(_ error: Error) -> String {
        "(\(type(of: error))) \(String(describing: error))"
    }
}
