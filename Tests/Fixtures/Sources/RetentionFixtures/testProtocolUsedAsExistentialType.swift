import Foundation

protocol FixtureProtocol119 {
    func protocolFunc()
}

public class FixtureClass119 {
    func existentialParameter(param: FixtureProtocol119?) {
        print(param ?? "")
    }

    public func retainer() {
        let value: FixtureProtocol119? = nil
        existentialParameter(param: value)
    }
}
