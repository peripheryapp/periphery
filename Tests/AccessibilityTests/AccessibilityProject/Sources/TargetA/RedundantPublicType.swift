import Foundation

public class RedundantPublicType {
    public func redundantPublicFunction() {}
}

public class RedundantPublicTypeRetainer {
    public init() {}
    public func retain() {
        let type = RedundantPublicType()
        type.redundantPublicFunction()
    }
}
