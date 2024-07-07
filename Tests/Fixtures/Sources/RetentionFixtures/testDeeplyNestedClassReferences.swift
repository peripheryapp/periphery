import Foundation

class FixtureClass17 {
    func someMethod() {}

    class FixtureClass18 {
        let a: FixtureClass17

        init(a: FixtureClass17) {
            self.a = a
        }

        func someMethod() {
            a.someMethod()
        }

        class FixtureClass19 {
            let b: FixtureClass18

            init(b: FixtureClass18) {
                self.b = b
            }

            func someMethod() {
                b.someMethod()
            }
        }
    }
}
