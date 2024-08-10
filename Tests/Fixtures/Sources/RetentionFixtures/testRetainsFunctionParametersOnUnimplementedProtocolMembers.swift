import Foundation

protocol FixtureProtocol126 {
    func unimplementedFunc(param: String)
}

extension FixtureProtocol126 {
    // A default implementation isn't considered a true implementation.
    func unimplementedFunc(param: String) {}
}

public class FixtureProtocol126Retainer {
    public func retain() {
        let v: FixtureProtocol126? = nil
        v?.unimplementedFunc(param: "")
    }
}
