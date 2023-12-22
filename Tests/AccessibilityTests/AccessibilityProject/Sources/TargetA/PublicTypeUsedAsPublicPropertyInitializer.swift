public struct PublicTypeUsedAsPublicPropertyInitializer_Simple {}
public struct PublicTypeUsedAsPublicPropertyInitializer_GenericParameter: Hashable {}

public class PublicTypeUsedAsPublicPropertyInitializer {
    public init() {}

    public var retain: [Any] {
        [simpleInitializer, genericParameter]
    }

    public var simpleInitializer = PublicTypeUsedAsPublicPropertyInitializer_Simple()
    public var genericParameter = Set<PublicTypeUsedAsPublicPropertyInitializer_GenericParameter>()
}
