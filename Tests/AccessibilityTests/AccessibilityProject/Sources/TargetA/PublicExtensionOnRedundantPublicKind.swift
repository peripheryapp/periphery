import Foundation

public class PublicExtensionOnRedundantPublicKind {}
public extension PublicExtensionOnRedundantPublicKind {
    func someFunc() {}
}

public class PublicExtensionOnRedundantPublicKindRetainer {
    public init() {}
    public func retain() {
        let _ = PublicExtensionOnRedundantPublicKind()
    }
}
