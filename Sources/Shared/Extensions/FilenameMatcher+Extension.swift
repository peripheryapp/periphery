import Foundation
import FilenameMatcher

public extension FilenameMatcher {
    init(relativePattern: String, to base: String, caseSensitive: Bool) {
        let patternComponents = relativePattern.split(separator: "/", omittingEmptySubsequences: false)
        let parentTraversalCount = patternComponents.firstIndex { $0 != ".." } ?? 0

        if parentTraversalCount > base.split(separator: "/").count {
            self.init(pattern: "")
            return
        }

        let baseComponents = base.split(separator: "/", omittingEmptySubsequences: false)
        let traversedPattern = patternComponents.dropFirst(parentTraversalCount).joined(separator: "/")
        let traversedBaseParts = baseComponents.dropLast(parentTraversalCount)
        let traversedBase = traversedBaseParts.joined(separator: "/")
        let normalizedBase = traversedBase.hasSuffix("/") ? traversedBase : "\(traversedBase)/"
        let shouldPrependPwd = !["/", "*"].contains { relativePattern.hasPrefix($0) }
        let pattern = shouldPrependPwd ? "\(normalizedBase)\(traversedPattern)" : traversedPattern
        self.init(pattern: pattern, caseSensitive: caseSensitive)
    }
}
