import Foundation

protocol FixtureProtocol83: AnyObject {
    func protocolMethod()
}

extension FixtureProtocol83 {
    func protocolMethod() {}
}

class FixtureClass83: FixtureProtocol83 {}

class FixtureClass84: FixtureClass83 {
    func protocolMethod() {}
}

public class FixtureClass85 {
    private let cls: FixtureClass84
    weak var delegate: FixtureProtocol83?

    init() {
        cls = FixtureClass84()
    }

    public func someMethod() {
        delegate?.protocolMethod()
    }
}

public class FixturePrincipleClass {}
