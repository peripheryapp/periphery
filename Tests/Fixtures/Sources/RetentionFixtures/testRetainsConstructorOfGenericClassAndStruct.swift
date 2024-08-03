import Foundation

class FixtureClass61<T> {
    init(someVar: T) {}
}

struct FixtureStruct61<T> {
    let someVar: T

    init(someVar: T) {
        self.someVar = someVar
    }
}

public class FixtureClass62 {
    private let classProperty: FixtureClass61<Int>
    private let structProperty: FixtureStruct61<Int>

    public init() {
        classProperty = FixtureClass61<Int>(someVar: 1)
        structProperty = FixtureStruct61<Int>(someVar: 1)
    }
}
