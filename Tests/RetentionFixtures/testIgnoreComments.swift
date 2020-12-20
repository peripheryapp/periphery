import Foundation

// periphery:ignore
public class Fixture113 {
    func someFunc(param: String) {
        Fixture114().referencedFunc()
    }
}

public protocol Fixture114Protocol {
    // periphery:ignore:parameters param
    func protocolFunc(param: String)
}

public class Fixture114 {
    func referencedFunc() {}

    // periphery:ignore:parameters b,c
    public func someFunc(a: String, b: String, c: String) {
        print(a)
    }
}

extension Fixture114: Fixture114Protocol {
    // param is ignored becuse the protocol ignores it.
    public func protocolFunc(param: String) {}
}
