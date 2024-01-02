import Foundation

protocol FixtureProtocol128_Inherited {
    func funcA()
}

protocol FixtureProtocol128: FixtureProtocol128_Inherited {
    func funcB()
}

public class FixtureClass134: FixtureProtocol128 {
    func funcA() {}
    func funcB() {}
}
