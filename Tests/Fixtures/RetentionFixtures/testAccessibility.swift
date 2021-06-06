import Foundation

public class FixtureClass31 {
    public required init(arg: Int) {}

    open func openFunc() {}

    public class FixtureClass31Inner {
        private func privateFunc() {}
    }
}

private class FixtureClass32 {
    public var publicVar: String?
}

class FixtureClass33 {}

enum Enum1 {
    public func publicEnumFunc() {}
}

public class FixtureClass50 {}

extension FixtureClass50 {
    public func publicMethodInExtension() {}
}

public extension FixtureClass50 {
    static let staticVarInExtension: String? = ""
    func methodInPublicExtension() {}
    static func staticMethodInPublicExtension() {}
    private func privateMethodInPublicExtension() {}
    internal func internalMethodInPublicExtension() {}
}

public extension Array {
    func methodInExternalStructTypeExtension() {}
}

public extension Sequence { // protocol
    func methodInExternalProtocolTypeExtension() {}
}

public extension Notification.Name {
    static let CustomNotification = Notification.Name("CustomNotification")
}
