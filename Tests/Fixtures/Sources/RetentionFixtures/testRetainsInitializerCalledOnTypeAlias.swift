class FixtureClass219 {
    init(foo: Int) {}
}

public class FixtureClass219Retainer {
    typealias FixtureClass219Aliased = FixtureClass219

    public func retain() {
        _ = Self.FixtureClass219Aliased(foo: 1)
    }
}
