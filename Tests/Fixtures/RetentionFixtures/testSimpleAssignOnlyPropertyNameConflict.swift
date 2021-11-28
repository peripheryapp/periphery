import Foundation

public class FixtureClass131 {
    static var someProperty: String?
    var someProperty: String

    public init() {
        someProperty = ""
        Self.someProperty = ""
    }

    public func someMethod() {
        _ = Self.someProperty
    }
}
