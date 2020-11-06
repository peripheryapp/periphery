import Foundation

protocol FixtureProtocol100 {
    var someGetSetVar: Bool { get set }
}

extension FixtureProtocol100 {
    var someGetSetVar: Bool {
        get { return false }
        set { }
    }
}

class FixtureClass100: NSObject, FixtureProtocol100 {
    var someGetSetVar: Bool { return true }
}

public class FixtureClass100Retainer {
    public func someMethod() {
        let obj: NSObject = FixtureClass100()
        if let protoObj = obj as? FixtureProtocol100 {
            print(protoObj.someGetSetVar)
        }
    }
}
