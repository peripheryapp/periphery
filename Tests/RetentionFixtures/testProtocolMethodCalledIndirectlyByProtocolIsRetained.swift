import Foundation

protocol FixtureProtocol52 {
    init()
    func protocolMethod()
}

class FixtureClass52: FixtureProtocol52 {
    required init() {}
    func protocolMethod() {}
}

public class FixtureClass53 {
    private let things: [FixtureProtocol52.Type] = [FixtureClass52.self]

    init() {
        things.forEach {
            let cls = $0.init()
            cls.protocolMethod()
        }
    }
}
