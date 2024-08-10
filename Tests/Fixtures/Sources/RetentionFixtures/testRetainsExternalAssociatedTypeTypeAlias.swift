import Foundation
import ExternalModuleFixtures

struct Fixture110: ExternalAssociatedType {
    typealias Value = Void
}

public struct Fixture110Retainer {
    public func someFunc() {
        print(Fixture110.self)
    }
}
