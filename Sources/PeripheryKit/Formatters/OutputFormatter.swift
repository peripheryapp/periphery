import Foundation

enum OutputFormat: String, CustomStringConvertible {
    case xcode
    case csv
    case json

    static let `default` = OutputFormat.xcode

    static var allCases: [OutputFormat] {
        return [.xcode, .csv, .json]
    }

    static func make(named name: String) throws -> OutputFormat {
        guard let outputFormat = OutputFormat(rawValue: name) else {
            throw PeripheryKitError.invalidFormatter(name: name)
        }

        return outputFormat
    }

    var formatter: OutputFormatter.Type {
        switch self {
        case .xcode:
            return XcodeFormatter.self
        case .csv:
            return CsvFormatter.self
        case .json:
            return JsonFormatter.self
        }
    }

    var supportsAuxiliaryOutput: Bool {
        if self == .xcode { return true }
        return false
    }

    var description: String {
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

protocol OutputFormatter: AnyObject {
    static func make() -> Self
    func perform(_ declarations: [Declaration]) throws
}
