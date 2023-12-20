public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType1 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType2 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType3 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType4 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType5 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType6 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType7 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType8 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType9 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_1 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_2 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_3 {}
public protocol PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType11 {}

public class PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnTypeRetainer {
    public init() {}

    public var retain: [Any] {
        [retain1, retain2, retain3, retain4, retain5, retain6, retain7, retain8, retain9, retain10,
         retain11]
    }

    public let retain1 = simpleReturn(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType1.self)
    public let (retain2, retain3, retain4) = (
        simpleReturn(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType2.self),
        simpleReturn(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType3.self),
        nonMetatypeReturn(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType4.self)
    )
    public let (retain5, (retain6, retain7)) = (simpleReturn(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType5.self), (simpleReturn(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType6.self), simpleReturn(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType7.self)))
    public let retain8 = closureReturn(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType8.self)
    public let retain9 = closureParameter(PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType9.self)
    public let retain10 = multipleParameters(
        PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_1.self,
        PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_2.self,
        PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType10_3.self
    )
    public let retain11 = complexReturn(ofType: PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnType11.self)

    private static func closureReturn<T>(_ type: T.Type) -> () -> T {
        fatalError()
    }

    private static func closureParameter<T>(_ type: T.Type) -> (T) -> Void {
        fatalError()
    }

    private static func simpleReturn<T>(_ type: T.Type) -> T {
        fatalError()
    }

    private static func complexReturn<T>(ofType type: T.Type) -> ComplexReturnClassOuter.Inner<T> {
        fatalError()
    }

    /// Even though C is not returned, it's assumed to be publicly accessible because it's too
    /// complex to solve for the scenario where the call site argument positions do not match the
    /// function signature parameter positions. Parameters with default arguments can result in
    /// misalignment.
    private static func multipleParameters<A, B, C>(_ typeA: A.Type, _ typeB: B.Type, _ typeC: C.Type) -> (A, B) {
        fatalError()
    }

    private static func nonMetatypeReturn<T>(_ type: T.Type) -> String {
        ""
    }
}

public class ComplexReturnClassOuter {
    public class Inner<T> {}
}
