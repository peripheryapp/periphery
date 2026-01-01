import Foundation
import SwiftUI

enum LocalizationUsage {
    static func useStrings() {
        _ = NSLocalizedString("swiftui_used_key", comment: "")
    }

    static func textView() -> some View {
        Text("swiftui_text_key")
    }
}

