import Foundation

class FixtureClass90 {
    func someMethod() {
        FixtureClass91().someMethod()
    }
}

class FixtureClass91 {
    func someMethod() {
        FixtureClass90().someMethod()
    }
}
