import Foundation

@propertyWrapper class Fixture111Wrapper {
    var projectedValue: Bool = false

    var wrappedValue: String {
        didSet { wrappedValue = wrappedValue.capitalized }
    }

    init(wrappedValue: String) {
        self.wrappedValue = wrappedValue.capitalized
    }
}

public class Fixture111 {
    @Fixture111Wrapper
    var someVar: String = ""
}

public class Fixture111Retainer {
    public func someFunc() {
        print(Fixture111().$someVar)
    }
}
