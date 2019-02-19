import Foundation

public class FixtureClass108 {
    public func someMethod() {
        let title = [String](title: "Title").first
        print(title)
    }
}

extension Array where Element == String {
    init(title: String) {
        self = [title]
    }
}
