import Foundation

protocol FixtureProtocol98 {
    func method1()
    func method2()
}

class FixtureClass98 {
    func method1() {}
}

extension FixtureClass98: FixtureProtocol98 {
    func method2() {}
}

public class FixtureClass98Retainer {
    public func someMethod() {
        let a: FixtureProtocol98 = FixtureClass98()
        a.method1()
        a.method2()
    }
}
