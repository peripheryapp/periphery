import Foundation

// Outer retained class just to ensure we're not only checking root declarations.
public class FixtureClass99Outer {
    class FixtureClass99 {
        var someVar: String = ""

        init() {
            someMethod()
        }

        func someMethod() {
            print(someVar)
        }
    }
}
