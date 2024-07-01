protocol SomeProtocol919 {
    func protocolMethod()
}

class SomeClass919: SomeProtocol919 {
    func protocolMethod() {}
}

public struct DepsHandler {
    public func depsMethod() {
        someProtocol.protocolMethod()
    }
}

extension DepsHandler {
    var someProtocol: SomeProtocol919 {
        SomeClass919()
    }
}
