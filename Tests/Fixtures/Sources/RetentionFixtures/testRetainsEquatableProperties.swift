import Foundation

public struct FixtureStruct222: Equatable {
    let unused: Int

    init(unused: Int) {
        self.unused = unused
    }
}

public struct FixtureStruct223: Hashable {
    let unused: Int

    init(unused: Int) {
        self.unused = unused
    }
}

public final class FixtureClass222: Equatable {
    let unused: Int

    init(unused: Int) {
        self.unused = unused
    }

    public static func == (lhs: FixtureClass222, rhs: FixtureClass222) -> Bool {
        true
    }
}
