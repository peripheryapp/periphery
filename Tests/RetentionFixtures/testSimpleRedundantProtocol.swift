import Foundation

protocol FixtureProtocol114 {
    func someFunc()
}

public class FixtureClass114: FixtureProtocol114 {
    func someFunc() {}
}

public class FixtureClass115 {}

extension FixtureClass115: FixtureProtocol114 {
    func someFunc() {}
}

public struct FixtureStruct116: FixtureProtocol114 {
    func someFunc() {}
}
