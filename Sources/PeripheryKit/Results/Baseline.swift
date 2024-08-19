import Foundation

/// A baseline set of declarations that are excluded from results.
public enum Baseline: Codable {
    case v1(usrs: [String])

    public var usrs: Set<String> {
        switch self {
        case let .v1(usrs):
            Set(usrs)
        }
    }
}
