import Foundation

class FixtureClass81Base {
    func someMethod() {}
}

class FixtureClass81Sub: FixtureClass81Base {
    // Method does not call super.someMethod(), therefore the base method is unused.
    override func someMethod() {}
}

public class FixtureClass81Retainer {
    var cls: FixtureClass81Sub?

    public func retainingMethod() {
        cls?.someMethod()
    }
}
