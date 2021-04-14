import Foundation

public protocol PublicTypeUsedAsPublicClassGenericRequirement_Protocol {}
public class PublicTypeUsedAsPublicClassGenericRequirement_ConformingClass: PublicTypeUsedAsPublicClassGenericRequirement_Protocol {}

public class PublicTypeUsedAsPublicClassGenericRequirementRetainer<T> where T: PublicTypeUsedAsPublicClassGenericRequirement_Protocol {
    public init() {}
}
