import ArgumentParser

public enum SonarQubeRuleSeverity: String, CaseIterable, ExpressibleByArgument {
    case blocker = "BLOCKER"
    case critical = "CRITICAL"
    case major = "MAJOR"
    case minor = "MINOR"
    case info = "INFO"

    public static let `default`: Self = .info

    init?(anyValue: Any) {
        if let option = anyValue as? Self {
            self = option
            return
        }
        guard let stringValue = anyValue as? String else { return nil }

        self.init(rawValue: stringValue)
    }
}
