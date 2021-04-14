import Foundation

public class PublicTypeUsedAsPublicFunctionParameterType {}
public class PublicTypeUsedAsPublicFunctionParameterTypeClosureArgument {}
public class PublicTypeUsedAsPublicFunctionParameterTypeClosureReturnType {}

public class PublicTypeUsedAsPublicFunctionParameterTypeRetainer {
    public init() {}
    public func retain1(type1: PublicTypeUsedAsPublicFunctionParameterType? = nil) {}
    public func retain2(type: ((PublicTypeUsedAsPublicFunctionParameterTypeClosureArgument) -> Void)? = nil) {}
    public func retain3(type: (() -> PublicTypeUsedAsPublicFunctionParameterTypeClosureReturnType)? = nil) {}
}
