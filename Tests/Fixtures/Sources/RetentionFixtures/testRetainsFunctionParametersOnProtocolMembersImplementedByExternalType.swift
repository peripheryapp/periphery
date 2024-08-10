import Foundation

protocol FixtureProtocol125 {
    func object(forKey key: String) -> Any?
}

extension UserDefaults: FixtureProtocol125 {}

public class FixtureProtocol125Retainer {
    public func retain() {
        let defaults: FixtureProtocol125 = UserDefaults.standard
        _ = defaults.object(forKey: "")
    }
}
