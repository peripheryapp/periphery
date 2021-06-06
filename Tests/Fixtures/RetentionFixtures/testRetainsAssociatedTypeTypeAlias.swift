import Foundation

protocol Fixture87State {
    associatedtype AssociatedType = Void
}

struct Fixture87AssociatedType {}

enum Fixture87MyState: Fixture87State {
    typealias AssociatedType = Fixture87AssociatedType
}

class Fixture87StateMachine<T: Fixture87State> {
    func someFunction(_ type: T.AssociatedType) {}
}

public class FixtureClass87Usage {
    public func somePublicFunction() {
        let sm = Fixture87StateMachine<Fixture87MyState>()
        sm.someFunction(Fixture87AssociatedType())
    }
}
