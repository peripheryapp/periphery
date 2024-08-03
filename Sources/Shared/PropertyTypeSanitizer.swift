import Foundation

public struct PropertyTypeSanitizer {
    @inlinable
    public static func sanitize(_ value: Any) -> [String]? {
        guard let typedValue = value as? [String] else { return nil }
        return typedValue.map { sanitize($0) }
    }

    @inlinable
    public static func sanitize(_ type: String) -> String {
        type.trimmed.trimmingCharacters(in: .init(["?", "!"]))
    }
}
