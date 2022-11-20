import Foundation

public class PublicTypeUsedInPublicClosureReturnType {}
public class PublicTypeUsedInPublicClosureInputType {}

public class PublicTypeUsedInPublicClosureRetainer {
    public var closure = { (a: PublicTypeUsedInPublicClosureInputType) -> PublicTypeUsedInPublicClosureReturnType in
        PublicTypeUsedInPublicClosureReturnType()
    }
    public init() {}
}
