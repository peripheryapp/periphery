import Foundation

public extension Set {
    mutating func inserting(_ value: Element) -> Self {
        insert(value)
        return self
    }
}
