import Foundation

public enum CommentCommand: CustomStringConvertible, Hashable {
    public enum Override: CustomStringConvertible, Hashable {
        case location(String, Int, Int)
        case kind(String)

        public var description: String {
            switch self {
            case let .location(path, line, column):
                "location=\"\(path):\(line):\(column)\""
            case let .kind(kind):
                "kind=\"\(kind)\""
            }
        }
    }

    case ignore
    case ignoreAll
    case ignoreParameters([String])
    case override([Override])

    public var description: String {
        switch self {
        case .ignore:
            return "ignore"
        case .ignoreAll:
            return "ignore:all"
        case let .ignoreParameters(params):
            let formattedParams = params.sorted().joined(separator: ",")
            return "ignore:parameters \(formattedParams)"
        case let .override(overrides):
            let formattedOverrides = overrides.map(\.description).joined(separator: " ")
            return "override \(formattedOverrides)"
        }
    }
}
