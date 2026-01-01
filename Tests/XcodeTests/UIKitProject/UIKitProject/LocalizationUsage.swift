import Foundation

enum LocalizationUsage {
    static func useStrings() {
        _ = NSLocalizedString("used_string_key", comment: "")
        _ = String(localized: "another_used_key")
    }
}

