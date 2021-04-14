import Foundation

public class PublicTypeUsedInPublicFunctionBody {}

public class PublicTypeUsedInPublicFunctionBodyRetainer {
    public init() {}
    public func retain() {
        _ = PublicTypeUsedInPublicFunctionBody()
    }
}
