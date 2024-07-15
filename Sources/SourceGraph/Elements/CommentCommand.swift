import Foundation

public enum CommentCommand: CustomStringConvertible, Hashable {
    case ignore
    case ignoreAll
    case ignoreParameters([String])
    
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
