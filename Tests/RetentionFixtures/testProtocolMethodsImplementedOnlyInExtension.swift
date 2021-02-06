import Foundation

protocol ProtocolWithExtension { }

extension ProtocolWithExtension {
    func used() { }
    func unused() { }
}

public class ProtocolWithExtensionRetainer: ProtocolWithExtension {
    public func someMethod() {
        used()
    }
}
