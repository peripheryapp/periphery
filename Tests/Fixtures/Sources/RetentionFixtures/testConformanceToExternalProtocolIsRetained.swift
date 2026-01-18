import Foundation

class FixtureClass55: Equatable {
    static func == (lhs: FixtureClass55, rhs: FixtureClass55) -> Bool {
        return true
    }
}

public class FixtureClass55Retainer {
    public func retain() {
        _ = FixtureClass55.self
    }
}