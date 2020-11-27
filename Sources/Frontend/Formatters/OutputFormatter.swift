import Foundation
import Shared
import PeripheryKit

protocol OutputFormatter: AnyObject {
    static func make() -> Self
    func perform(_ declarations: [Declaration]) throws
}

extension OutputFormatter {
    var redundantConformanceHint: String { "redundantConformance" }

    func describe(_ hint: Analyzer.Hint?) -> String? {
        switch hint {
        case .redundantProtocol(_):
            return "redundantProtocol"
        case .assignOnlyProperty:
            return "assignOnlyProperty"
        default:
            return nil
        }
    }

    func describeResults(for declaration: Declaration, colored: Bool) -> [(SourceLocation, String)] {
        var description: String = ""
        var secondaryResults: [(SourceLocation, String)] = []

        if var name = declaration.name {
            if let kind = declaration.kind.displayName, let first_ = kind.first {
                let first = String(first_)
                description += "\(first.uppercased())\(kind.dropFirst()) "
            }

            name = colored ? colorize(name, .lightBlue) : name
            description += "'\(name)'"

            if let hint = declaration.analyzerHint {
                switch hint {
                case let .redundantProtocol(references):
                    description += " is redundant as it's never used as an existential type"
                    secondaryResults = references.map {
                        ($0.location, "Protocol '\(name)' conformance is redundant")
                    }
                case .assignOnlyProperty:
                    description += " is assigned, but never used"
                }
            } else {
                description += " is unused"
            }
        } else {
            description += "unused"
        }

        return [(declaration.location, description)] + secondaryResults
    }
}

extension OutputFormat {
    var formatter: OutputFormatter.Type {
        switch self {
        case .xcode:
            return XcodeFormatter.self
        case .csv:
            return CsvFormatter.self
        case .json:
            return JsonFormatter.self
        case .checkstyle:
            return CheckstyleFormatter.self
        }
    }
}
