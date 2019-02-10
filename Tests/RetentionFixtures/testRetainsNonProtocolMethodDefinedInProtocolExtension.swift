import Foundation

protocol FixtureProtocol66 {
    func protocolMethod()
}

extension FixtureProtocol66 {
    func nonProtocolMethod() {}
}

public class FixtureClass66: FixtureProtocol66 {
    func protocolMethod() {}

    public func someMethod() {
        nonProtocolMethod()
    }
}
