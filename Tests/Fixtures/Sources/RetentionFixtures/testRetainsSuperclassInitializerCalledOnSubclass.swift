class FixtureClass221Parent {
    init(param: String) {}
}

class FixtureClass221Child: FixtureClass221Parent {}

public class FixtureClass221Retainer {
    public func retain() {
        _ = FixtureClass221Child(param: "foo")
    }
}
