// periphery:ignore
final class InitializerRedundantPublicAccessibilityRetainer {
    // periphery:ignore
    func retain() {
        _ = InitializerRedundantPublicAccessibility()
    }
}

public class InitializerRedundantPublicAccessibility {
    public init() {}
}
