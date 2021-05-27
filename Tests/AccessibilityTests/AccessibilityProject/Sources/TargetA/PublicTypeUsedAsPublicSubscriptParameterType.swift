import Foundation

public class PublicTypeUsedAsPublicSubscriptParameterType {}

public class PublicTypeUsedAsPublicSubscriptParameterTypeRetainer {
    public init() {}
    public subscript(_ type: PublicTypeUsedAsPublicSubscriptParameterType? = nil) -> Int { 0 }
}
