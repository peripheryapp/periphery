import Configuration
import Foundation
import Logger
import SourceGraph
import SystemPackage

public protocol OutputFormatter: AnyObject {
    var configuration: Configuration { get }
    var logger: Logger { get }
    var currentFilePath: FilePath { get }

    init(configuration: Configuration, logger: Logger)
    func format(_ results: [ScanResult], colored: Bool) throws -> String?
}

extension OutputFormatter {
    func redundantConformanceHint(with inherited: Set<String>) -> String {
        var msg = "redundantConformance"
        if !inherited.isEmpty {
            msg += "(replace with: '\(inherited.sorted().joined(separator: ", "))')"
        }

        return msg
    }

    func describe(_ annotation: ScanResult.Annotation) -> String {
        switch annotation {
        case .unused:
            "unused"
        case .assignOnlyProperty:
            "assignOnlyProperty"
        case .redundantProtocol:
            "redundantProtocol"
        case .redundantPublicAccessibility:
            "redundantPublicAccessibility"
        case .redundantInternalAccessibility:
            "redundantInternalAccessibility"
        case .redundantFilePrivateAccessibility:
            "redundantFilePrivateAccessibility"
        case .superfluousIgnoreCommand:
            "superfluousIgnoreCommand"
        }
    }

    func describe(_ result: ScanResult, colored: Bool) -> [(Location, String)] {
        var description = ""
        var secondaryResults: [(Location, String)] = []
        let location = declarationLocation(from: result.declaration)
        let kindDisplayName = declarationKindDisplayName(from: result.declaration)

        if var name = result.declaration.name {
            name = colored ? logger.colorize(name, .lightBlue) : name

            switch result.annotation {
            case .unused:
                description += "Unused \(kindDisplayName) '\(name)'"
            case .assignOnlyProperty:
                description += "Assign-only \(kindDisplayName) '\(name)' is assigned, but never used"
            case let .redundantProtocol(references, inherited):
                description += "Redundant protocol '\(name)' (never used as an existential type)"
                secondaryResults = references.map {
                    var msg = "Redundant protocol conformance '\(name)'"

                    if !inherited.isEmpty {
                        msg += " (replace with '\(inherited.sorted().joined(separator: ", "))')"
                    }

                    return ($0.location, msg)
                }
            case let .redundantPublicAccessibility(modules):
                let modulesJoined = modules.sorted().joined(separator: ", ")
                description += "Redundant public accessibility for \(kindDisplayName) '\(name)' (not used outside of \(modulesJoined))"
            case let .redundantInternalAccessibility(suggestedAccessibility):
                let accessibilityText = suggestedAccessibility?.rawValue ?? "private/fileprivate"
                description += "Redundant internal accessibility for \(kindDisplayName) '\(name)' (not used outside of file; can be \(accessibilityText))"
            case let .redundantFilePrivateAccessibility(containingTypeName):
                let context = containingTypeName.map { "only used within \($0)" } ?? "not used outside of file"
                description += "Redundant fileprivate accessibility for \(kindDisplayName) '\(name)' (\(context); can be private)"
            case .superfluousIgnoreCommand:
                description += "Superfluous ignore comment for \(kindDisplayName) '\(name)' (declaration is referenced and should not be ignored)"
            }
        } else {
            description += "Unused"
        }

        return [(location, description)] + secondaryResults
    }

    func outputPath(_ location: Location) -> FilePath {
        var path = location.file.path.lexicallyNormalized()

        if configuration.relativeResults, path.isAbsolute {
            path = path.relativeTo(currentFilePath).removingRoot()
        }

        return path
    }

    func locationDescription(_ location: Location) -> String {
        [
            outputPath(location).string,
            String(location.line),
            String(location.column),
        ]
        .joined(separator: ":")
    }

    func declarationKind(from declaration: Declaration) -> String {
        var kind = declaration.kind.rawValue

        if let overrideKind = declaration.commentCommands.kindOverride {
            kind = overrideKind
        }

        return kind
    }

    func declarationKindDisplayName(from declaration: Declaration) -> String {
        var kind = declaration.kind.displayName

        if let overrideKind = declaration.commentCommands.kindOverride {
            kind = overrideKind
        }

        return kind
    }

    func declarationLocation(from declaration: Declaration) -> Location {
        var location = declaration.location

        if let override = declaration.commentCommands.locationOverride {
            let (path, line, column) = override
            let sourceFile = SourceFile(path: path, modules: [])
            let overrideLocation = Location(file: sourceFile, line: line, column: column)
            location = overrideLocation
        }

        return location
    }
}

public extension OutputFormat {
    var formatter: OutputFormatter.Type {
        switch self {
        case .xcode:
            XcodeFormatter.self
        case .csv:
            CsvFormatter.self
        case .codeclimate:
            CodeClimateFormatter.self
        case .json:
            JsonFormatter.self
        case .checkstyle:
            CheckstyleFormatter.self
        case .githubActions:
            GitHubActionsFormatter.self
        case .githubMarkdown:
            GitHubMarkdownFormatter.self
        case .gitlabCodeQuality:
            GitLabCodeQualityFormatter.self
        }
    }
}
