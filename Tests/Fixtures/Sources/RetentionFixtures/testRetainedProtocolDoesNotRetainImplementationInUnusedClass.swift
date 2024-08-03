import Foundation

protocol FixtureProtocol200 {
    func protocolFunc()
}

class FixtureClass200 {}

class FixtureClass201 {}

extension FixtureClass200: FixtureProtocol200 {
    func protocolFunc() {
        print(FixtureClass201.self)
    }
}

public class FixtureClass202 {
    public func someFunc() {
        // Retain the protocol only
        let x: FixtureProtocol200? = nil
        x?.protocolFunc()
    }
}
