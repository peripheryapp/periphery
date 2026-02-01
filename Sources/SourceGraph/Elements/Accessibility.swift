import Foundation

public enum Accessibility: String, Comparable {
    case `private`
    case `fileprivate`
    case `internal`
    case `public`
    case open

    private var sortOrder: Int {
        switch self {
        case .private: 0
        case .fileprivate: 1
        case .internal: 2
        case .public: 3
        case .open: 4
        }
    }

    public static func < (lhs: Accessibility, rhs: Accessibility) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
