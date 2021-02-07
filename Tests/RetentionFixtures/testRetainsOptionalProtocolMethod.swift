#if os(macOS)
// It appears optional protocol members aren't supported on Linux?
import Foundation

@objc protocol FixtureProtocol127 {
    @objc optional func optionalFunc()
}

public class FixtureClass127: FixtureProtocol127 {
    public func someFunc() {
        let p: FixtureProtocol127? = nil
        p?.optionalFunc?()
    }
}
#endif
