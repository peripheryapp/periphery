import Foundation

/// A baseline set of declarations that are excluded from results.
public enum Baseline: Codable {
    case v1(usrs: [String])

    var usrs: Set<String> {
        switch self {
        case .v1(let usrs):
            return Set(usrs)
        }
    }
}
