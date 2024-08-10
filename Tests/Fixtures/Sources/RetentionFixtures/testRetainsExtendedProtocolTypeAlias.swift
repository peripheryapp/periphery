public protocol FixtureProtocol216 {}
public class FixtureClass216: FixtureProtocol216 {}

private typealias Fixture216TypeAlias = FixtureProtocol216
extension Fixture216TypeAlias {
    var someExtensionProperty: Int { 0 }
}

public class FixtureClass216Retainer {
    public func retain() {
        let cls: FixtureProtocol216 = FixtureClass216()
        _ = cls.someExtensionProperty
    }
}
