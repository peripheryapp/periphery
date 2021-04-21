import Foundation

protocol FixtureProtocol124 {
    var someProperty: Int? { get set }
}

class FixtureClass124: FixtureProtocol124 {
    var someProperty: Int?
}

public class FixtureClass124Retainer {
    public func retain() {
        var cls: FixtureProtocol124 = FixtureClass124()
        cls.someProperty = 1
    }
}
