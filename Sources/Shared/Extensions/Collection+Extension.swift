import Foundation

public extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    @inlinable
    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
