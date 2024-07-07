import Foundation

public class FixtureClass67 {
    func someMethod() {}

    public func retainingMethod() {
        someMethod()
    }
}

public class FixtureClass68: FixtureClass67 {
    override func someMethod() {}
}
