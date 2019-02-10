import Foundation
import Cocoa

protocol FixtureProtocol100 {
    var someGetSetVar: Bool { get set }
}

extension FixtureProtocol100 {
    var someGetSetVar: Bool {
        get { return false }
        set { }
    }
}

class FixtureClass100: NSView, FixtureProtocol100 {
    var someGetSetVar: Bool { return true }
}

public class FixtureClass100Retainer {
    public func someMethod() {
        let view: NSView = FixtureClass100()
        if let protoView = view as? FixtureProtocol100 {
            print(protoView.someGetSetVar)
        }
    }
}
