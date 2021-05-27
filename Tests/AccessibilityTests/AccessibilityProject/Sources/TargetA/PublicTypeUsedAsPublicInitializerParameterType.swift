import Foundation

public class PublicTypeUsedAsPublicInitializerParameterType {}

public class PublicTypeUsedAsPublicInitializerParameterTypeRetainer {
    public init(_ cls: PublicTypeUsedAsPublicInitializerParameterType? = nil) {}
}
