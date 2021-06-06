import Foundation
import RetentionFixturesCrossModule

struct Fixture110: ExternalAssociatedType {
    typealias Value = Void
}

public struct Fixture110Retainer {
    public func someFunc() {
        print(Fixture110.self)
    }
}
