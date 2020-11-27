import Foundation

public enum CommentCommand: CustomStringConvertible, Hashable {
    case ignore
    case ignoreAll
    case ignoreParameters([String])

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

    public var description: String {
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
