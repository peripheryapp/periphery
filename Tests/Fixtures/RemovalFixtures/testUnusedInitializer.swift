public class UnusedInitializer {
    public init(used: Int) {}
    init(unused1: Int) {}
}

extension UnusedInitializer {
    convenience init(unused2: Int) {
        self.init(unused1: unused2)
    }
}
