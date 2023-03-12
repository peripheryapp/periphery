public class FixtureClass214 {}

private typealias Fixture214TypeAlias = FixtureClass214
extension Fixture214TypeAlias {
    var someExtensionProperty: Int { 0 }
}

public class FixtureClass214Retainer {
    public func retain() {
        _ = FixtureClass214().someExtensionProperty
    }
}
