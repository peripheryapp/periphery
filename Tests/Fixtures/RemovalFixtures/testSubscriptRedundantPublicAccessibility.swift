// periphery:ignore
final class SubscriptRedundantPublicAccessibilityRetainer {
    // periphery:ignore
    func retain() {
        _ = SubscriptRedundantPublicAccessibility()[1]
    }
}

public final class SubscriptRedundantPublicAccessibility {
    public subscript(param: Int) -> Int {
        return 0
    }
}

