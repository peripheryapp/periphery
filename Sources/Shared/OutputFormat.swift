import Foundation

public enum OutputFormat: String, CaseIterable {
    case xcode
    case csv
    case json
    case checkstyle
    case codeclimate
    case githubActions = "github-actions"

    public static let `default` = OutputFormat.xcode

    init?(anyValue: Any) {
        if let format = anyValue as? OutputFormat {
            self = format
            return
        }
        guard let stringValue = anyValue as? String else { return nil }
        self.init(rawValue: stringValue)
    }

    @inlinable
    public var supportsAuxiliaryOutput: Bool {
        self == .xcode
    }
}
