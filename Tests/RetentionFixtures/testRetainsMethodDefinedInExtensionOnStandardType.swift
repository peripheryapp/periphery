import Foundation

public extension String {
    var trimmed: String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

public class FixtureClass35 {
    public func testSomething() {
        print("hello".trimmed)
    }
}
