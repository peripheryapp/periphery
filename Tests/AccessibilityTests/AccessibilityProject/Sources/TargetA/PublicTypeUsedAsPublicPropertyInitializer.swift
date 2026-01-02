public struct PublicTypeUsedAsPublicPropertyInitializer_Simple {}
public struct PublicTypeUsedAsPublicPropertyInitializer_GenericParameter: Hashable {}

public enum PublicTypeUsedAsPublicPropertyInitializer_ArrayLiteralEnum {
    case foo
}

public enum PublicTypeUsedAsPublicPropertyInitializer_DictLiteralKeyEnum: Hashable {
    case key
}

public enum PublicTypeUsedAsPublicPropertyInitializer_DictLiteralValueEnum {
    case value
}

public enum PublicTypeUsedAsPublicPropertyInitializer_DirectMemberAccessEnum {
    case bar
}

public enum PublicTypeUsedAsPublicPropertyInitializer_SetLiteralEnum: Hashable {
    case baz
}

public enum PublicTypeUsedAsPublicPropertyInitializer_TernaryEnum {
    case a
    case b
}

public class PublicTypeUsedAsPublicPropertyInitializer {
    public init() {}

    public var retain: [Any] {
        [simpleInitializer, genericParameter, arrayLiteralInitializer, dictLiteralInitializer,
         directMemberAccess, setLiteralInitializer, ternaryInitializer]
    }

    public var simpleInitializer = PublicTypeUsedAsPublicPropertyInitializer_Simple()
    public var genericParameter = Set<PublicTypeUsedAsPublicPropertyInitializer_GenericParameter>()
    public var arrayLiteralInitializer = [PublicTypeUsedAsPublicPropertyInitializer_ArrayLiteralEnum.foo]
    public var dictLiteralInitializer = [PublicTypeUsedAsPublicPropertyInitializer_DictLiteralKeyEnum.key: PublicTypeUsedAsPublicPropertyInitializer_DictLiteralValueEnum.value]
    public var directMemberAccess = PublicTypeUsedAsPublicPropertyInitializer_DirectMemberAccessEnum.bar
    public var setLiteralInitializer = Set([PublicTypeUsedAsPublicPropertyInitializer_SetLiteralEnum.baz])
    public var ternaryInitializer = true ? PublicTypeUsedAsPublicPropertyInitializer_TernaryEnum.a : PublicTypeUsedAsPublicPropertyInitializer_TernaryEnum.b
}
