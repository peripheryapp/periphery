import Foundation

@propertyWrapper class Fixture111Wrapper {
    var projectedValue: Bool = false

    var wrappedValue: String {
        didSet { wrappedValue = wrappedValue.capitalized }
    }

    init(wrappedValue: String, block: () -> Void) {
        self.wrappedValue = wrappedValue.capitalized
    }
}

public class Fixture111 {
    @Fixture111Wrapper(block: buildBlock())
    var someVar: String = ""

    static func buildBlock() -> () -> Void {
        return {}
    }
}

public class Fixture111Retainer {
    public func someFunc() {
        print(Fixture111().$someVar)
    }
}
