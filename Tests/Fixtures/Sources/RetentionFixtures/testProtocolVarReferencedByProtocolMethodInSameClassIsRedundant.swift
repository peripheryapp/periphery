import Foundation

protocol FixtureProtocol51 {
    var protocolVar: String { get }
    func protocolMethod()
}

public class FixtureClass51: FixtureProtocol51 {
    var protocolVar: String {
        return "hi"
    }

    func protocolMethod() {
        print(protocolVar)
    }

    public func publicMethod() {
        protocolMethod()
    }
}
