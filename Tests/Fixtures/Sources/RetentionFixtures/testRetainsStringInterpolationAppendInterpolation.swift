import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation(test value: Int) {
        appendInterpolation(value)
    }
}

public struct Fixture112 {
    public func someFunc() {
        print("test: \(test: 1)")
    }
}
