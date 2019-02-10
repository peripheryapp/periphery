import Foundation

protocol FixtureProtocol107 {
    func myFunc(param: String)
}

extension FixtureProtocol107 {
    func myFunc(param: String) {}
}

public class FixtureClass107Class1: FixtureProtocol107 {
    func myFunc(param: String) {}
}

public class FixtureClass107Class2: FixtureProtocol107 {
    func myFunc(param: String) {}
}
