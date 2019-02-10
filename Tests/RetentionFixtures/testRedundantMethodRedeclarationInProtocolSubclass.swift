import Foundation

protocol Fixture85ParentProtocol {
    func protocolMethod()
}

protocol Fixture85ChildProtocol: Fixture85ParentProtocol {
    // This is redundant with the requirements of Fixture85ParentProtocol, though accepted by the compiler.
    func protocolMethod()
}

class Fixture85ChildProtocolImpl: Fixture85ChildProtocol {
    func protocolMethod() {}
}

public class Fixture85Retainer {
    public func publicMethod() {
        let impl = Fixture85ChildProtocolImpl()
        perform(parentProtocol: impl)
    }

    func perform(parentProtocol: Fixture85ParentProtocol) {
        parentProtocol.protocolMethod()
    }
}
