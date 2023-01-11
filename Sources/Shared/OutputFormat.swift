import Foundation

public enum OutputFormat: String, CaseIterable {
    case xcode
    case csv
    case json
    case checkstyle
    case codeclimate

    public static let `default` = OutputFormat.xcode

    init?(anyValue: Any) {
        self.init(rawValue: anyValue as? String ?? "")
    }

    public var supportsAuxiliaryOutput: Bool {
        self == .xcode
    }
}
