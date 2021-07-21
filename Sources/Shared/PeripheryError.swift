import Foundation

public enum PeripheryError: Error, LocalizedError, CustomStringConvertible {
    case shellCommandFailed(cmd: String, args: [String], status: Int32, output: String)
    case shellOuputEncodingFailed(cmd: String, args: [String], encoding: String.Encoding)
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
    case swiftVersionUnsupportedError(version: String)
    case unindexedTargetsError(targets: Set<String>, indexStorePath: String)

    public var errorDescription: String? {
        switch self {
        case let .shellCommandFailed(cmd, args, status, output):
            let joinedArgs = args.joined(separator: " ")
            return "Shell command '\(cmd) \(joinedArgs)' returned exit status '\(status)':\n\(output)"
        case let .shellOuputEncodingFailed(cmd, args, encoding):
            let joinedArgs = args.joined(separator: " ")
            return "Shell command '\(cmd) \(joinedArgs)' output encoding to \(encoding) failed."
        case let .usageError(message):
            return message
        case let .underlyingError(error):
            return "(\(type(of: error))) \(String(describing: error))" 
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
        case let .swiftVersionUnsupportedError(version):
            return "This version of Periphery only supports Swift >= 5.3, you're using \(version)."
        }
    }

    public var description: String {
        return errorDescription!
    }
}
