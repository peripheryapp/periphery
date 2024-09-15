import Extensions
import Foundation

public enum PropertyTypeSanitizer {
    @inlinable
    public static func sanitize(_ type: String) -> String {
        type.trimmed.trimmingCharacters(in: .init(["?", "!"]))
    }
}
