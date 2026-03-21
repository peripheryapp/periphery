import Foundation

public enum PublicTypeUsedAsPublicFunctionThrowType: Error {
    case generic
}

public struct PublicTypeUsedAsPublicFunctionThrowTypeRetainer {
    public init() {}
    public func retain() throws(PublicTypeUsedAsPublicFunctionThrowType) {}
}
