import Foundation

public class PublicTypeUsedAsPublicSubscriptReturnType {}

public class PublicTypeUsedAsPublicSubscriptReturnTypeRetainer {
    public init() {}
    public subscript(_ idx: Int = 0) -> PublicTypeUsedAsPublicSubscriptReturnType { .init() }
}
