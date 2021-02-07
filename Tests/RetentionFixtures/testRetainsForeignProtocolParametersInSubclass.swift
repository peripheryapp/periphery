import Foundation

public class ForeignProtocolClass: NSCopying {
    public func copy(with zone: NSZone?) -> Any {
        ForeignProtocolClass()
    }
}

public class ForeignProtocolSubclass: ForeignProtocolClass {
    public override func copy(with zone: NSZone?) -> Any {
        ForeignProtocolSubclass()
    }
}
