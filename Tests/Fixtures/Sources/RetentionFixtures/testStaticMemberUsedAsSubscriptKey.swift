enum FixtureEnum128 {
    static let someVar = ""
}

public class FixtureClass128 {
    public func someFunc() {
        var s: [String: Int] = [:]
        s[FixtureEnum128.someVar] = 0
    }
}
