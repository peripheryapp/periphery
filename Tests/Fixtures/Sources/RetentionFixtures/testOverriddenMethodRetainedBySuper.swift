import Foundation

class FixtureClass82Base {
    func someMethod() {}
}

class FixtureClass82Sub: FixtureClass82Base {
    override func someMethod() {
        super.someMethod()
    }
}

public class FixtureClass82Retainer {
    var cls: FixtureClass82Sub?

    public func retainingMethod() {
        cls?.someMethod()
    }
}
