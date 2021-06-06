import Foundation

struct FixtureStruct3 {
    static let instance = Self(someVar: 123)

    let someVar: Int

    init(someVar: Int) {
        self.someVar = someVar
    }
}


public struct FixtureStruct3Retainer {
    public func retainer() {
        print(FixtureStruct3.instance.someVar)
    }
}
