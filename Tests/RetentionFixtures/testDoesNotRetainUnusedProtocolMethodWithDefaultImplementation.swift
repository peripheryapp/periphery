import Foundation

protocol FixtureProtocol84 {
    func usedMethod()
    func unusedMethod()
}

extension FixtureProtocol84 {
    func usedMethod() {}
    func unusedMethod() {}
}

public class FixtureClass86: FixtureProtocol84 {
    public func someMethod() {
        usedMethod()
    }
}
