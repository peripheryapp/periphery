public protocol FixtureProtocol38<Value> {
    associatedtype Value
}

public extension FixtureProtocol38<Int> {
    func someFunc() {}
}

public protocol FixtureProtocol39<Value, Value2> {
    associatedtype Value
    associatedtype Value2
}

public extension FixtureProtocol39<Int, Int> {
    func someFunc() {}
}

public protocol FixtureProtocol40<Value, Value2> {
    associatedtype Value
    associatedtype Value2
}

public extension FixtureProtocol40 where Value == Int, Value2 == Int {
    func someFunc() {}
}
