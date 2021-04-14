import Foundation

public class PublicTypeUsedAsPublicFunctionReturnType {}
public class PublicTypeUsedAsPublicFunctionReturnTypeClosureArgument {}
public class PublicTypeUsedAsPublicFunctionReturnTypeClosureReturnType {}

public class PublicTypeUsedAsPublicFunctionReturnTypeRetainer {
    public init() {}
    public func retain1() -> PublicTypeUsedAsPublicFunctionReturnType {
        PublicTypeUsedAsPublicFunctionReturnType()
    }

    public func retain2() -> (PublicTypeUsedAsPublicFunctionReturnTypeClosureArgument) -> Void {
        let closure: (PublicTypeUsedAsPublicFunctionReturnTypeClosureArgument) -> Void = { _ in }
        return closure
    }

    public func retain3() -> () -> PublicTypeUsedAsPublicFunctionReturnTypeClosureReturnType {
        let closure: () -> PublicTypeUsedAsPublicFunctionReturnTypeClosureReturnType = {
            PublicTypeUsedAsPublicFunctionReturnTypeClosureReturnType()
        }
        return closure
    }
}
