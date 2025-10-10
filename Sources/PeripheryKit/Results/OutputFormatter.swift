import Configuration
import Foundation
import Logger
import SourceGraph
import SystemPackage

public protocol OutputFormatter: AnyObject {
    var configuration: Configuration { get }
    var currentFilePath: FilePath { get }

    init(configuration: Configuration)
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
        }
    }

    func describe(_ result: ScanResult, colored: Bool) -> [(Location, String)] {
        var description = ""
        var secondaryResults: [(Location, String)] = []
        let location = declarationLocation(from: result.declaration)
        let kindDisplayName = declarationKindDisplayName(from: result.declaration)

        if var name = result.declaration.name {
            description += "\(kindDisplayName.first?.uppercased() ?? "")\(kindDisplayName.dropFirst()) "
            name = colored ? Logger.colorize(name, .lightBlue) : name
            description += "'\(name)'"

            switch result.annotation {
            case .unused:
                description += " is unused"
            case .assignOnlyProperty:
                description += " is assigned, but never used"
            case let .redundantProtocol(references, inherited):
                description += " is redundant as it's never used as an existential type"
                secondaryResults = references.map {
                    var msg = "Protocol '\(name)' conformance is redundant"

                    if !inherited.isEmpty {
                        msg += ", replace with '\(inherited.sorted().joined(separator: ", "))'"
                    }

                    return ($0.location, msg)
                }
            case let .redundantPublicAccessibility(modules):
                let modulesJoined = modules.sorted().joined(separator: ", ")
                description += " is declared public, but not used outside of \(modulesJoined)"
            case let .redundantInternalAccessibility(files):
                let filesJoined = files.sorted { $0.path.string < $1.path.string }.map { $0.path.string }.joined(separator: ", ")
                description += " is declared internal, but not used outside of \(filesJoined)"
            case let .redundantFilePrivateAccessibility(files):
                let filesJoined = files.sorted { $0.path.string < $1.path.string }.map { $0.path.string }.joined(separator: ", ")
                description += " is declared fileprivate, but not used outside of \(filesJoined)"
            }
        } else {
            description += "unused"
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

        for command in declaration.commentCommands {
            switch command {
            case let .override(overrides):
                for override in overrides {
                    switch override {
                    case let .kind(overrideKind):
                        kind = overrideKind
                    default:
                        break
                    }
                }
            default:
                break
            }
        }

        return kind
    }

    func declarationKindDisplayName(from declaration: Declaration) -> String {
        var kind = declaration.kind.displayName

        for command in declaration.commentCommands {
            switch command {
            case let .override(overrides):
                for override in overrides {
                    switch override {
                    case let .kind(overrideKind):
                        kind = overrideKind
                    default:
                        break
                    }
                }
            default:
                break
            }
        }

        return kind
    }

    func declarationLocation(from declaration: Declaration) -> Location {
        var location = declaration.location

        for command in declaration.commentCommands {
            switch command {
            case let .override(overrides):
                for override in overrides {
                    switch override {
                    case let .location(file, line, column):
                        let sourceFile = SourceFile(path: FilePath(String(file)), modules: [])
                        let overrideLocation = Location(file: sourceFile, line: line, column: column)
                        location = overrideLocation
                    default:
                        break
                    }
                }
            default:
                break
            }
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
