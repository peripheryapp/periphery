import Foundation
import PathKit

public enum PeripheryError: Error, LocalizedError, CustomStringConvertible {
    case shellCommandFailed(cmd: String, args: [String], status: Int32, output: String)
    case shellOuputEncodingFailed(cmd: String, args: [String], encoding: String.Encoding)

    case usageError(String)
    case underlyingError(Error)
    case invalidFormatter(name: String)
    case invalidScheme(name: String, project: String)
    case invalidTarget(name: String, project: String)
    case testTargetNotBuildable(name: String)
    case sourceGraphIntegrityError(message: String)
    case guidedSetupError(message: String)
    case updateCheckError(message: String)
    case xcodebuildNotConfigured
    case pathDoesNotExist(path: String)
    case foundIssues(count: Int)
    case packageError(message: String)

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
            return String(describing: error)
        case .invalidFormatter(let name):
            let formatters = OutputFormat.allCases.map { $0.rawValue }.joined(separator: ", ")
            return "Invalid formatter '\(name)'. Available formatters are: \(formatters)."
        case let .invalidScheme(name, project):
            return "Scheme '\(name)' does not exist in '\(project)'."
        case let .invalidTarget(name, project):
            return "Target '\(name)' does not exist in '\(project)'."
        case .testTargetNotBuildable(let name):
            return "Test target '\(name)' is not built by any of the given schemes."
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
        }
    }

    public var hint: String? {
        switch self {
        case .xcodebuildNotConfigured:
            return "You may need to change the path to your Xcode.app if it has a different name."
        case let .shellCommandFailed(_, _, _, output):
            if output.contains("EXPANDED_CODE_SIGN_IDENTITY: unbound variable") {
                return "You appear to be affected by a bug in CocoaPods (https://github.com/CocoaPods/CocoaPods/issues/8000). Please upgrade to CocoaPods >= 1.6.0, run 'pod install' and try again."
            }

            return nil
        default:
            return nil
        }
    }

    public var description: String {
        return errorDescription!
    }
}
