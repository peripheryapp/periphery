import Foundation

public class FixtureClass95 {
    private static var someVar: String!

    init() {
        FixtureClass95.someVar = "hello"
    }

    private var someVar: String! {
        return FixtureClass95.someVar
    }

    public func testSomething() {
        print(someVar ?? "")
    }
}
