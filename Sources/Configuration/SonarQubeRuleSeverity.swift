public enum SonarQubeRuleSeverity: String, CaseIterable {
    case blocker = "BLOCKER"
    case critical = "CRITICAL"
    case major = "MAJOR"
    case minor = "MINOR"
    case info = "INFO"

    public static let `default`: Self = .info
}
