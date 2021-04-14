import Foundation

public class PublicTypeUsedAsPublicPropertyType {}
public struct PublicTypeUsedAsPublicPropertyGenericArgumentType: Hashable {}
public class PublicTypeUsedAsPublicPropertyArrayType {}

public class PublicTypeUsedAsPublicPropertyTypeRetainer {
    public init() {}
    public var retain1: PublicTypeUsedAsPublicPropertyType?
    public var retain2: Set<PublicTypeUsedAsPublicPropertyGenericArgumentType>?
    public var retain3: [PublicTypeUsedAsPublicPropertyArrayType] = []
}
