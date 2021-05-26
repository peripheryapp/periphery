import Foundation

internal class PublicDeclarationInInternalParent {
    public func somePublicFunc() {}
}

public class PublicDeclarationInInternalParentRetainer {
    public init() {}
    public func retain() {
        PublicDeclarationInInternalParent().somePublicFunc()
    }
}
