import Foundation

protocol FixtureProtocol80 {
    func protocolMethod()
    func protocolMethodWithUnusedDefault()
}

extension FixtureProtocol80 {
    func protocolMethod() {}
    func protocolMethodWithUnusedDefault() {}
}

public class FixtureClass80: FixtureProtocol80 {
    func protocolMethodWithUnusedDefault() {}

    public func someMethod() {
        protocolMethod()
    }
}

public class FixtureProtocol80Retainer {
    var proto: FixtureProtocol80?

    public init() {
        proto?.protocolMethodWithUnusedDefault()
    }
}
