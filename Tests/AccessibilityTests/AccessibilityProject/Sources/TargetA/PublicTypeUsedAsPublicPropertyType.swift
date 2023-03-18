import Foundation

public class PublicTypeUsedAsPublicPropertyType1 {}
public class PublicTypeUsedAsPublicPropertyType2 {}
public class PublicTypeUsedAsPublicPropertyType3 {}
public class PublicTypeUsedAsPublicPropertyType4 {}
public class PublicTypeUsedAsPublicPropertyType5 {}
public struct PublicTypeUsedAsPublicPropertyGenericArgumentType: Hashable {}
public class PublicTypeUsedAsPublicPropertyArrayType {}

public class PublicTypeUsedAsPublicPropertyTypeRetainer {
    public init() {}

    public var retain: [Any?] {
        [retain1, retain2, retain3, retain4, retain5, retain6, retain7]
    }

    public var retain1: PublicTypeUsedAsPublicPropertyType1?
    public var retain2: Set<PublicTypeUsedAsPublicPropertyGenericArgumentType>?
    public var retain3: [PublicTypeUsedAsPublicPropertyArrayType] = []
    public var (retain4, (retain5, retain6)): (PublicTypeUsedAsPublicPropertyType2, (PublicTypeUsedAsPublicPropertyType3, PublicTypeUsedAsPublicPropertyType4)) = (.init(), (.init(), .init()))
    public var retain7 = someFunc()

    private static func someFunc() -> PublicTypeUsedAsPublicPropertyType5 { .init() }
}
