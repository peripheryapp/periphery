import SourceGraph
import SwiftSyntax
import SystemPackage

extension CommentCommand {
    static func parseCommands(in trivia: Trivia?) -> [CommentCommand] {
        let comments: [String] = trivia?.compactMap {
            switch $0 {
            case let .lineComment(comment),
                 let .blockComment(comment),
                 let .docLineComment(comment),
                 let .docBlockComment(comment):
                comment
            default:
                nil
            }
        } ?? []

        return comments
            .compactMap { comment in
                guard let range = comment.range(of: "periphery:") else { return nil }
                var rawCommand = String(comment[range.upperBound...]).replacingOccurrences(of: "*/", with: "").trimmed
                // Anything after '-' in a comment command is ignored.
                rawCommand = String(rawCommand.split(separator: "-").first ?? "").trimmed
                return CommentCommand.parse(rawCommand)
            }
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

                    overrides.append(.location(String(file), line, column))
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
