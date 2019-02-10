import Foundation

protocol FixtureProtocol97 {
    var someProtocolVar: Int { get }
    func someProtocolMethod1()
    func someProtocolMethod2()
    func someUnusedProtocolMethod()
}

class FixtureClass97Base1 {
    func someProtocolMethod1() {}
    var someProtocolVar: Int = 0
}

class FixtureClass97Base2: FixtureClass97Base1 {
    func someProtocolMethod2() {}
    func someUnusedProtocolMethod() {}
}

class FixtureClass97: FixtureClass97Base2, FixtureProtocol97 {}

public class FixtureClass97Retainer {
    public func someMethod() {
        let cls: FixtureProtocol97 = FixtureClass97()
        cls.someProtocolMethod1()
        cls.someProtocolMethod2()
        print(cls.someProtocolVar)
        // someUnusedProtocolMethod() not used
    }
}
