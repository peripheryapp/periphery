import Foundation

class FixtureClass14 {
    func someMethod() {}
}

class FixtureClass15 {
    let a: FixtureClass14

    init(a: FixtureClass14) {
        self.a = a
    }

    func someMethod() {
        a.someMethod()
    }
}

class FixtureClass16 {
    let b: FixtureClass15

    init(b: FixtureClass15) {
        self.b = b
    }

    func someMethod() {
        b.someMethod()
    }
}
