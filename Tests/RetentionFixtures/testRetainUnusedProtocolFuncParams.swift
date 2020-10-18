import Foundation

public protocol FixtureProtocol107 {
    func myFunc(param: String)
}

public extension FixtureProtocol107 {
    func myFunc(param: String) {}
}

public class FixtureClass107Class1: FixtureProtocol107 {
    public func myFunc(param: String) {}
}

public class FixtureClass107Class2: FixtureProtocol107 {
    public func myFunc(param: String) {}
}
