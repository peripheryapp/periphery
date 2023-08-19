// periphery:ignore
final class ClassRedundantPublicAccessibilityRetainer {
    // periphery:ignore
    func retain() {
        ClassRedundantPublicAccessibility().someFunc()
    }
}

public final class ClassRedundantPublicAccessibility {
    public func someFunc() {}
}
