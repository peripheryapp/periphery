import Foundation

public class PublicClassInheritingPublicExternalClass: FileManager {
    public override init() {}
}

public class PublicClassInheritingPublicExternalClassRetainer {
    public init() {
        let _ = PublicClassInheritingPublicExternalClass()
    }
}
