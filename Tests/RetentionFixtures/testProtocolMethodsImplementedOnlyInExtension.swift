import Foundation

protocol FixtureProtocol115 { }

extension FixtureProtocol115 {
    func used() { }
    func unused() { }
}

public class FixtureProtocol115Retainer: FixtureProtocol115 {
    public func someMethod() {
        used()
    }
}
