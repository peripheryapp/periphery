private struct FixtureStruct120_Collection<P: FixtureProtocol120> {
    let items: [P.AssociatedType]
}

private protocol FixtureProtocol120 {
    associatedtype AssociatedType
}

private struct FixtureStruct120: FixtureProtocol120 {
    enum AssociatedType: String {
        case hello
    }
    let result = FixtureStruct120_Collection<Self>(items: [.hello])
}

public class Fixture120Retainer {
    public func retain() {
        _ = FixtureStruct120().result
    }
}
