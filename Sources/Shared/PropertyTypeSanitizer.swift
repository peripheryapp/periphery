import Foundation

public enum PropertyTypeSanitizer {
    @inlinable
    public static func sanitize(_ types: [String]) -> [String] {
        types.map { sanitize($0) }
    }

    @inlinable
    public static func sanitize(_ type: String) -> String {
        type.trimmed.trimmingCharacters(in: .init(["?", "!"]))
    }
}
