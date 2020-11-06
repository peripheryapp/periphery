import Foundation

public enum OutputFormat: String, CaseIterable {
    case xcode
    case csv
    case json

    static let `default` = OutputFormat.xcode

    public static func make(named name: String) throws -> OutputFormat {
        guard let outputFormat = OutputFormat(rawValue: name) else {
            throw PeripheryError.invalidFormatter(name: name)
        }

        return outputFormat
    }

    public var supportsAuxiliaryOutput: Bool {
        if self == .xcode { return true }
        return false
    }
}

extension OutputFormat: CustomStringConvertible {
    public var description: String {
        switch self {
        case .xcode:
            return "Xcode"
        case .json:
            return "JSON"
        case .csv:
            return "CSV"
        }
    }
}
