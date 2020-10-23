import Foundation

class SyntaxFixture20 {
    init(someVar: Int = 0) {}
}

class SyntaxFixture20Generic {
    init<T>(type: T.Type) {}
}

class SyntaxFixture20Optional {
    init?(someVar: Int = 0) {}
}
