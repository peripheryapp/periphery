import Foundation

enum Accessibility: String {
    case `public` = "source.lang.swift.accessibility.public"
    case `internal` = "source.lang.swift.accessibility.internal"
    case `private` = "source.lang.swift.accessibility.private"
    case `fileprivate` = "source.lang.swift.accessibility.fileprivate"
    case `open` = "source.lang.swift.accessibility.open"

    var shortName: String {
        let namespace = "source.lang.swift.accessibility"
        let index = rawValue.index(after: namespace.endIndex)
        return String(rawValue.suffix(from: index))
    }

    static let all: [Accessibility] = [.public, .internal, .private, .fileprivate, .open]
}
