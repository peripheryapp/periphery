private typealias Fixture215TypeAlias = Int
extension Fixture215TypeAlias {
    var someExtensionProperty: Int { 0 }
}

public class FixtureClass215Retainer {
    public func retain() {
        _ = 0.someExtensionProperty
    }
}
