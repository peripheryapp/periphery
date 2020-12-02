import Foundation

class FixtureClass120 { // deliberately not public
    public func retainedFunc() {
        FixtureClass121().unusedFunc1()
    }
}

public class FixtureClass121 {
    func unusedFunc1() {
        unusedFunc2() // cyclic
        usedFunc2()
        print(FixtureClass122().unusedFunc())
    }

    func unusedFunc2() {
        unusedFunc1()  // cyclic
    }

    public func usedFunc1() { // deliberately public
        usedFunc2()
    }

    func usedFunc2() { } // deliberately not public
}

class FixtureClass122 {
    func unusedFunc() { // referenced directly, ignored
        print(FixtureClass123.self)
    }
}

class FixtureClass123 {
    public func unusedFunc() { // deliberately public, not referenced, ignored
        print(FixtureClass124.self)
    }
}

class FixtureClass124 {
    func unusedFunc() {} // not referenced, ignored
}
