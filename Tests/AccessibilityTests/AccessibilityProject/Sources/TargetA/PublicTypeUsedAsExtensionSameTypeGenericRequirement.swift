public protocol PublicTypeUsedAsExtensionSameTypeGenericRequirement_Protocol {}

public struct PublicTypeUsedAsExtensionSameTypeGenericRequirement: PublicTypeUsedAsExtensionSameTypeGenericRequirement_Protocol {
    public init() {}
}

extension PublicTypeUsedAsExtensionSameTypeGenericRequirement_Protocol where Self == PublicTypeUsedAsExtensionSameTypeGenericRequirement {
    public static var defaultInstance: Self {
        PublicTypeUsedAsExtensionSameTypeGenericRequirement()
    }
}

public func takeExtensionSameTypeGenericRequirement<T: PublicTypeUsedAsExtensionSameTypeGenericRequirement_Protocol>(_ value: T) {
    _ = value
}
