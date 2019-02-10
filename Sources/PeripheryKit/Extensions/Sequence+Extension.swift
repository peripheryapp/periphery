import Foundation

extension Sequence {
    public func mapFirst<T>(_ transform: (Self.Element) throws -> T?) rethrows -> T? {
        for item in self {
            if let transformed = try transform(item) {
                return transformed
            }
        }

        return nil
    }
}
