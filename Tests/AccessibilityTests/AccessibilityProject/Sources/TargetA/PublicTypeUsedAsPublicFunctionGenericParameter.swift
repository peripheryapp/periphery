import Foundation

public protocol PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolA {}
public protocol PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolB {}
public class PublicTypeUsedAsPublicFunctionGenericParameter_ConformingClass: PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolA, PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolB {}

public class PublicTypeUsedAsPublicFunctionGenericParameterRetainer {
    public init() {}
    public func retain<T: PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolA & PublicTypeUsedAsPublicFunctionGenericParameter_ProtocolB>(_ type: T.Type) {}
}
