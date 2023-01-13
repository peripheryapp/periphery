import Foundation
import SystemPackage

public enum PeripheryError: Error, LocalizedError, CustomStringConvertible {
    case shellCommandFailed(cmd: String, args: [String], status: Int32, output: String)
    case shellOutputEncodingFailed(cmd: String, args: [String], encoding: String.Encoding)
    case usageError(String)
    case underlyingError(Error)
    case invalidScheme(name: String, project: String)
    case invalidTargets(names: [String], project: String)
    case testTargetsNotBuildable(names: [String])
    case sourceGraphIntegrityError(message: String)
    case guidedSetupError(message: String)
    case updateCheckError(message: String)
    case xcodebuildNotConfigured
    case pathDoesNotExist(path: String)
    case foundIssues(count: Int)
    case packageError(message: String)
    case swiftVersionParseError(fullVersion: String)
    case swiftVersionUnsupportedError(version: String, minimumVersion: String)
    case unindexedTargetsError(targets: Set<String>, indexStorePaths: [FilePath])
    case jsonDeserializationError(error: Error, json: String)
    case indexStoreNotFound(derivedDataPath: String)
    case conflictingIndexUnitsError(file: FilePath, module: String, unitTargets: Set<String>)

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
        case let .invalidTargets(names, project):
            let formattedNames = names.map { "'\($0)'" }.joined(separator: ", ")
            let declinedTarget = names.count == 1 ? "Target" : "Targets"
            let conjugatedDo = names.count == 1 ? "does" : "do"
            return "\(declinedTarget) \(formattedNames) \(conjugatedDo) not exist in '\(project)'."
        case .testTargetsNotBuildable(let names):
            let joinedNames = names.joined(separator: "', '")
            return "The following test targets are not built by any of the given schemes: '\(joinedNames)'"
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
        case let .unindexedTargetsError(targets, indexStorePath):
            let joinedTargets = targets.sorted().joined(separator: ", ")
            return "The index store at '\(indexStorePath)' does not contain data for the following targets: \(joinedTargets). Either the index store is outdated, or you have requested to scan targets that have not been built."
        case let .swiftVersionUnsupportedError(version, minimumVersion):
            return "This version of Periphery only supports Swift >= \(minimumVersion), you're using \(version)."
        case let .jsonDeserializationError(error, json):
            return "JSON deserialization failed: \(describe(error))\nJSON:\n\(json)"
        case let .indexStoreNotFound(derivedDataPath):
            return "Failed to find index datastore at path: \(derivedDataPath)"
        case let .conflictingIndexUnitsError(file, module, targets):
            var parts = ["Found conflicting index store units for '\(file)' in module '\(module)'."]
            if targets.count > 1 {
                parts.append("The units have conflicting build targets: \(targets.sorted().joined(separator: ", ")).")
            }
            parts.append("If you passed the '--index-store-path' option, ensure that Xcode is not open with a project that may write to this index store while Periphery is running.")
            return parts.joined(separator: " ")
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
