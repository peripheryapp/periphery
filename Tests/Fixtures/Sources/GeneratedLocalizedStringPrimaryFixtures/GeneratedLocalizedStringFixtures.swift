import Foundation

public enum GeneratedAssets {
    public static let strings = GeneratedStrings()
}

public final class GeneratedStrings {
    public let prompt = PromptStrings()
    public let verification = VerificationStrings()
    public let nsfwSetting = NSFWSettingStrings()
}

public final class PromptStrings {
    /// periphery:override kind="localized string" location="Fixtures/Generated.strings:9:1"
    public var title: String { "prompt.title" }
}

public final class VerificationStrings {
    /// periphery:override kind="localized string" location="Fixtures/Generated.strings:11:1"
    public var title: String { "verification.title" }
}

public final class NSFWSettingStrings {
    public let updated = UpdatedStrings()
}

public final class UpdatedStrings {
    /// periphery:override kind="localized string" location="Fixtures/Generated.strings:57:1"
    public var toast: String { "nsfwSetting.updated.toast" }
}
