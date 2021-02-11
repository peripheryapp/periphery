import Foundation

public class FixtureClass109: NSCopying {
    public func copy(with zone: NSZone?) -> Any {
        FixtureClass109()
    }
}

public class FixtureClass109Subclass: FixtureClass109 {
    public override func copy(with zone: NSZone?) -> Any {
        FixtureClass109Subclass()
    }
}
