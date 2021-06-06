import Foundation

open class FixtureClass112 {
    open func doSomething(with value: Int) { }
}

public class FixtureClass112Retainer {
    var instance: FixtureClass112?

    public func doSomething() {
        instance?.doSomething(with: .random(in: 0...10))
    }
}
