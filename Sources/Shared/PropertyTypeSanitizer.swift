import Foundation

public struct PropertyTypeSanitizer {
    public static func sanitize(_ type: String) -> String {
        type.trimmed.trimmingCharacters(in: .init(["?"]))
    }
}
