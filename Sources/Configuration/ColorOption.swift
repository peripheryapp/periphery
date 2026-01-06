public enum ColorOption: String, CaseIterable, Equatable {
    case auto
    case always
    case never

    public static let `default` = ColorOption.auto

    init?(anyValue: Any) {
        if let option = anyValue as? ColorOption {
            self = option
            return
        }
        guard let stringValue = anyValue as? String else { return nil }

        self.init(rawValue: stringValue)
    }
}
