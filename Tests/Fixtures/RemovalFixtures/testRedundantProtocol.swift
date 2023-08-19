protocol RedundantProtocol3_Existential1 {}
protocol RedundantProtocol3_Existential2 {}
protocol RedundantProtocol2: RedundantProtocol3_Existential1, RedundantProtocol3_Existential2 {}
protocol RedundantProtocol1 {}
class RedundantProtocolClass1: RedundantProtocol1, RedundantProtocol2, CustomStringConvertible {
    var description: String = ""
}
class RedundantProtocolClass2 {}
extension RedundantProtocolClass2: RedundantProtocol1 {}
class RedundantProtocolClass3 {
    class RedundantProtocolClass4: CustomStringConvertible, RedundantProtocol1 {
        var description: String = ""
    }
}

public class RedundantProtocolRetainer {
    public func retain() {
        _ = RedundantProtocolClass1()
        _ = RedundantProtocolClass2.self
        _ = RedundantProtocolClass3.RedundantProtocolClass4.self
    }
}
