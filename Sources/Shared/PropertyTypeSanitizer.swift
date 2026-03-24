import Extensions
import Foundation

public enum PropertyTypeSanitizer {
    /// Static so the CharacterSet is constructed once rather than on every call.
    private static let optionalSuffixes = CharacterSet(["?", "!"])

    public static func sanitize(_ type: String) -> String {
        type.trimmed.trimmingCharacters(in: optionalSuffixes)
    }
}
