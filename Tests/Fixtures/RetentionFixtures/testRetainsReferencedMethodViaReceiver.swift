import Foundation

class FixtureClass113 {
    static func make() -> Self {
        return self.init()
    }

    required init() {}
}

public class FixtureClass113Retainer {
    let instance = FixtureClass113.make()

    public func retainerFunc() {
        print(instance)
    }
}
