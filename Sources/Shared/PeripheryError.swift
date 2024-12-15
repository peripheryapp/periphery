import Foundation
import SystemPackage

public enum PeripheryError: Error, LocalizedError, CustomStringConvertible {
    case shellCommandFailed(cmd: [String], status: Int32, output: String)
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
    case changeCurrentDirectoryFailed(FilePath)

    public var errorDescription: String? {
        switch self {
        case let .shellCommandFailed(cmd, status, output):
            let joinedCmd = cmd.joined(separator: " ")
            return "Shell command '\(joinedCmd)' returned exit status '\(status)':\n\(output)"
        case let .shellOutputEncodingFailed(cmd, args, encoding):
            let joinedArgs = args.joined(separator: " ")
            return "Shell command '\(cmd) \(joinedArgs)' output encoding to \(encoding) failed."
        case let .usageError(message):
            return message
        case let .underlyingError(error):
            return describe(error)
        case let .invalidScheme(name, project):
            return "Scheme '\(name)' does not exist in '\(project)'."
        case let .sourceGraphIntegrityError(message):
            return message
        case let .guidedSetupError(message):
            return "\(message). Please refer to the documentation for instructions on configuring Periphery manually - https://github.com/peripheryapp/periphery/blob/master/README.md"
        case let .updateCheckError(message):
            return message
        case .xcodebuildNotConfigured:
            return "Xcode is not configured for command-line use. Please run 'sudo xcode-select -s /Applications/Xcode.app'."
        case let .pathDoesNotExist(path):
            return "No such file or directory: \(path)."
        case let .foundIssues(count):
            return "Found \(count) \(count > 1 ? "issues" : "issue")."
        case let .packageError(message):
            return message
        case let .swiftVersionParseError(fullVersion):
            return "Failed to parse Swift version from: \(fullVersion)"
        case let .swiftVersionUnsupportedError(version, minimumVersion):
            return "This version of Periphery only supports Swift >= \(minimumVersion), you're using \(version)."
        case let .jsonDeserializationError(error, json):
            return "JSON deserialization failed: \(describe(error))\nJSON:\n\(json)"
        case let .indexStoreNotFound(derivedDataPath):
            return "Failed to find index datastore at path: \(derivedDataPath)"
        case let .changeCurrentDirectoryFailed(path):
            return "Failed to change current directory to: \(path)"
        }
    }

    public var description: String {
        errorDescription!
    }

    // MARK: - Private

    private func describe(_ error: Error) -> String {
        "(\(type(of: error))) \(String(describing: error))"
    }
}
