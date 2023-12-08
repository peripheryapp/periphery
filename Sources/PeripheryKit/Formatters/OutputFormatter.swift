import Foundation
import Shared
import SystemPackage

public protocol OutputFormatter: AnyObject {
    var configuration: Configuration { get }
    var currentFilePath: FilePath { get }
    init(configuration: Configuration)
    func format(_ results: [ScanResult]) throws -> String
}

extension OutputFormatter {
    var redundantConformanceHint: String { "redundantConformance" }

    func describe(_ annotation: ScanResult.Annotation) -> String {
        switch annotation {
        case .unused:
            return "unused"
        case .assignOnlyProperty:
            return "assignOnlyProperty"
        case .redundantProtocol(_):
            return "redundantProtocol"
        case .redundantPublicAccessibility:
            return "redundantPublicAccessibility"
        }
    }

    func describe(_ result: ScanResult, colored: Bool) -> [(SourceLocation, String)] {
        var description: String = ""
        var secondaryResults: [(SourceLocation, String)] = []

        if var name = result.declaration.name {
            if let kind = result.declaration.kind.displayName, let first_ = kind.first {
                let first = String(first_)
                description += "\(first.uppercased())\(kind.dropFirst()) "
            }

            name = colored ? colorize(name, .lightBlue) : name
            description += "'\(name)'"

            switch result.annotation {
            case .unused:
                description += " is unused"
            case .assignOnlyProperty:
                description += " is assigned, but never used"
            case let .redundantProtocol(references):
                description += " is redundant as it's never used as an existential type"
                secondaryResults = references.map {
                    ($0.location, "Protocol '\(name)' conformance is redundant")
                }
            case let .redundantPublicAccessibility(modules):
                let modulesJoined = modules.sorted().joined(separator: ", ")
                description += " is declared public, but not used outside of \(modulesJoined)"
            }
        } else {
            description += "unused"
        }

        return [(result.declaration.location, description)] + secondaryResults
    }

    func outputPath(_ location: SourceLocation) -> FilePath {
        var path = location.file.path.lexicallyNormalized()

        if configuration.relativeResults {
            path = path.relativeTo(currentFilePath)
        }

        return path
    }

    func locationDescription(_ location: SourceLocation) -> String {
        [
            outputPath(location).string,
            String(location.line),
            String(location.column)
        ]
        .joined(separator: ":")
    }
}

public extension OutputFormat {
    var formatter: OutputFormatter.Type {
        switch self {
        case .xcode:
            return XcodeFormatter.self
        case .csv:
            return CsvFormatter.self
        case .codeclimate:
            return CodeClimateFormatter.self
        case .json:
            return JsonFormatter.self
        case .checkstyle:
            return CheckstyleFormatter.self
        }
    }
}
