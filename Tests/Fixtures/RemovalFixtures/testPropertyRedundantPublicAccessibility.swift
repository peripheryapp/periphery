// periphery:ignore
final class PropertyRedundantPublicAccessibilityRetainer {
    // periphery:ignore
    func retain() {
        _ = somePublicProperty
    }
}

public let somePublicProperty: Int = 1
