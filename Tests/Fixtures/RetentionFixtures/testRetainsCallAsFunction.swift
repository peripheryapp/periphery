import Foundation

struct FixtureStruct1 {
    var base: Int
    func callAsFunction(_ x: Int) -> Int {
        return base + x
    }
}

public struct FixtureStruct1Retainer {
    public func retain() {
        let add3 = FixtureStruct1(base: 3)
        _ = add3(10)
    }
}
