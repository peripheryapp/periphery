import SourceGraph
import SwiftSyntax
import SystemPackage

extension CommentCommand {
    static func parseCommands(in trivia: Trivia?) -> [CommentCommand] {
        trivia?.compactMap { piece -> CommentCommand? in
            // Extract comment text and marker length based on trivia piece kind
            let parsed: (comment: String, markerLength: Int)? = switch piece {
            case let .lineComment(text): (text, 2) // //
            case let .docLineComment(text): (text, 3) // ///
            case let .blockComment(text): (text, 2) // /*
            case let .docBlockComment(text): (text, 3) // /**
            default: nil
            }

            guard let (comment, markerLength) = parsed,
                  let range = comment.range(of: "periphery:") else { return nil }

            // Only respect commands at the start of a comment (after the marker and whitespace).
            let prefixStart = comment.index(comment.startIndex, offsetBy: markerLength)
            let prefixBeforeCommand = String(comment[prefixStart ..< range.lowerBound])
            guard prefixBeforeCommand.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

            var rawCommand = String(comment[range.upperBound...]).replacingOccurrences(of: "*/", with: "").trimmed
            // Anything after '-' in a comment command is ignored.
            rawCommand = String(rawCommand.split(separator: "-").first ?? "").trimmed
            return CommentCommand.parse(rawCommand)
        } ?? []
    }

    static func parse(_ rawCommand: String) -> Self? {
        if rawCommand == "ignore" {
            return .ignore
        } else if rawCommand == "ignore:all" {
            return .ignoreAll
        } else if rawCommand.hasPrefix("ignore:parameters") {
            guard let params = rawCommand.split(separator: " ").last?.split(separator: ",").map({ String($0).trimmed }) else { return nil }

            return .ignoreParameters(params)
        } else if rawCommand.hasPrefix("override") {
            let pattern = #/(?<key>\w+)="(?<value>[^"]*)"/#
            var params: [String: String] = [:]

            for match in rawCommand.matches(of: pattern) {
                let key = String(match.output.key)
                let value = String(match.output.value)
                params[key] = value
            }

            var overrides = [Override]()

            for (key, value) in params {
                switch key {
                case "location":
                    let parts = value.split(separator: ":")
                    guard let file = parts[safe: 0] else { break }

                    let line = Int(parts[safe: 1] ?? "1") ?? 1
                    let column = Int(parts[safe: 2] ?? "1") ?? 1
                    let filePath = FilePath(String(file)).makeAbsolute()

                    overrides.append(.location(filePath, line, column))
                case "kind":
                    overrides.append(.kind(value))
                default:
                    break
                }
            }

            return .override(overrides)
        }

        return nil
    }
}
