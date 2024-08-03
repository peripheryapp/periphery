import Foundation

protocol Fixture88State {
    associatedtype AssociatedType = Void
}

struct Fixture88AssociatedType {}

enum Fixture88MyState: Fixture88State {
    typealias AssociatedType = Fixture88AssociatedType
}

class Fixture88StateMachine<T: Fixture88State> {
    func someFunction() {}
}

public class FixtureClass88Usage {
    public func somePublicFunction() {
        let sm = Fixture88StateMachine<Fixture88MyState>()
        sm.someFunction()
    }
}
