import Foundation

class FixtureClass61<T> {
    init(someVar: Int = 0) {}
}

public class FixtureClass62 {
    private let other: FixtureClass61<String>

    init() {
        other = FixtureClass61<String>()
    }
}
