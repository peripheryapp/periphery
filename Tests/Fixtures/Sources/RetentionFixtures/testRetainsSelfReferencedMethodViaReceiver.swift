import Foundation

class FixtureClass92 {
    func someFunc() {}

    func someOtherFunc() {
        let a = FixtureClass92()
        a.someFunc()
    }
}

public class FixtureClass92Retainer {
    public func someFunc() {
        FixtureClass92().someOtherFunc()
    }
}
