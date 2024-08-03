import Foundation

struct FixtureStruct3 {
    static let instance = Self(value: 1)
    init(value: Int) {}
}

struct FixtureStruct4 {
    init(value: Int) {}
}

extension FixtureStruct4 {
    static func someFunc() {
        _ = Self(value: 1)
    }
}

struct FixtureStruct5 {
    init(value: Int) {}
}

public struct FixtureStruct3Retainer {
    public func retainer() {
        _ = FixtureStruct3.instance
        FixtureStruct4.someFunc()
        _ = FixtureStruct5.self
    }
}
