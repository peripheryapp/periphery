import Foundation
import SwiftSyntax

enum CommentCommand: CustomStringConvertible, Hashable {
    case ignore
    case ignoreAll
    case ignoreParameters([String])

    static func parseCommands(in trivia: Trivia?) -> [CommentCommand] {
        let comments: [String] = trivia?.compactMap {
            switch $0 {
            case let .lineComment(comment),
                 let .blockComment(comment),
                 let .docLineComment(comment),
                 let .docBlockComment(comment):
                return comment
            default:
                return nil
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
        }

        return nil
    }

    var description: String {
        switch self {
        case .ignore:
            return "ignore"
        case .ignoreAll:
            return "ignore:all"
        case let .ignoreParameters(params):
            let formattedParams = params.sorted().joined(separator: ",")
            return "ignore:parameters \(formattedParams)"
        }
    }
}
