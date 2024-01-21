// periphery:ignore
private final class Retainer {
    func retain() {
        redundantPublicAccessibilityWithAttributes()
    }
}

@available(*, message: "hi mum")
public func redundantPublicAccessibilityWithAttributes() {}
