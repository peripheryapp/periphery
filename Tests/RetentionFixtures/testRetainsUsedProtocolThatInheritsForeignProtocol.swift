import Foundation

protocol FixtureProtocol96: Comparable {
    var usedValue: Int { get }
    var unusedValue: Int { get }
}

extension FixtureProtocol96 {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.usedValue <= rhs.usedValue
    }
}

class FixtureClass96: NSObject, FixtureProtocol96 {
    var usedValue: Int = 0
    var unusedValue: Int = 0
}

public class FixtureClass96Retainer {
    public func sortThings() {
        let things = [
            FixtureClass96(),
            FixtureClass96()
        ]
        print(things.sorted())
    }
}
