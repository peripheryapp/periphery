// periphery:ignore
final class FunctionRedundantPublicAccessibilityRetainer {
    // periphery:ignore
    func retain() {
        somePublicFunc()
    }
}

public func somePublicFunc() {}
