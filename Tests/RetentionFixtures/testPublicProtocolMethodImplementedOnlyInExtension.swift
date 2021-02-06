import Foundation

public protocol PublicProtocolWithExtension { }

extension PublicProtocolWithExtension {
    public func used() { }
    func unused() { }
}
