import Foundation

public protocol PublicTypeUsedAsPublicFunctionGenericRequirement_Protocol {}
public class PublicTypeUsedAsPublicFunctionGenericRequirement_ConformingClass: PublicTypeUsedAsPublicFunctionGenericRequirement_Protocol {}

public class PublicTypeUsedAsPublicFunctionGenericRequirementRetainer {
    public init() {}
    public func retain<T>(_ type: T.Type) where T: PublicTypeUsedAsPublicFunctionGenericRequirement_Protocol {}
}
