import Foundation

public protocol FixtureProtocol27 {
    static func staticProtocolMethod()
    static var staticProtocolVar: String { get }
    func protocolMethod()
}

class FixtureClass27: FixtureProtocol27 {
    class func staticProtocolMethod() {}
    class var staticProtocolVar: String { return "test" }
    func protocolMethod() {}
}

public class FixtureClass27Retainer {
    var cls1: FixtureClass27
    var cls2: FixtureClass28

    init() {
        cls1 = FixtureClass27()
        cls2 = FixtureClass28()

        let conforming: FixtureProtocol28 = FixtureClass28()
        _  = type(of: conforming).overrideStaticProtocolMethod()
        _  = type(of: conforming).overrideStaticProtocolVar
    }
}

public protocol FixtureProtocol28: AnyObject {
    static func overrideStaticProtocolMethod()
    static var overrideStaticProtocolVar: String { get }
}

open class FixtureClass28Base: FixtureProtocol28 {
    open class func overrideStaticProtocolMethod() {}
    open class var overrideStaticProtocolVar: String { return "test" }
}

class FixtureClass28: FixtureClass28Base {
    override static func overrideStaticProtocolMethod() {}
    override static var overrideStaticProtocolVar: String { return "test" }
}
