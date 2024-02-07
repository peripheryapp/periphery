protocol SomeProtocol919 {
    func protocolMethod()
}

class SomeClass919: SomeProtocol919 {
    func protocolMethod() {}
}

public struct DepsHandler {
    public init() {}
}

extension DepsHandler {
    var someProtocol: SomeProtocol919 {
        SomeClass919()
    }
}
