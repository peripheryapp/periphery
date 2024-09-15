import Foundation

public extension Set {
    @inlinable
    mutating func inserting(_ value: Element) -> Self {
        insert(value)
        return self
    }
}
