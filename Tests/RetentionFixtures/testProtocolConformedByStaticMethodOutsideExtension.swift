import Foundation

public class FixtureClass64 {
    private let retainer: FixtureClass65

    init() {
        retainer = FixtureClass65()
    }
}

class FixtureClass65: Equatable {
}

func == (lhs: FixtureClass65, rhs: FixtureClass65) -> Bool {
    return true
}

func != (lhs: FixtureClass65, rhs: FixtureClass65) -> Bool {
    return false
}
