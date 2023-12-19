import Foundation

public struct PublicTypeUsedAsPublicFunctionParameterDefaultValue {
    public static let somePublicValue = 1
}

public class PublicTypeUsedAsPublicFunctionParameterDefaultValueRetainer {
    public init() {}

    public func somePublicFunc(value: Int = PublicTypeUsedAsPublicFunctionParameterDefaultValue.somePublicValue) {}
}
