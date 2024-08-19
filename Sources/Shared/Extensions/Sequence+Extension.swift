import Foundation

public extension Sequence {
    @inlinable
    func mapFirst<T>(_ transform: (Element) throws -> T?) rethrows -> T? {
        for item in self {
            if let transformed = try transform(item) {
                return transformed
            }
        }

        return nil
    }

    @inlinable
    func flatMapSet<T>(_ transform: (Element) throws -> Set<T>) rethrows -> Set<T> {
        try reduce(into: .init()) { result, element in
            try result.formUnion(transform(element))
        }
    }

    @inlinable
    func mapSet<T>(_ transform: (Element) throws -> T) rethrows -> Set<T> {
        try reduce(into: .init()) { result, element in
            try result.insert(transform(element))
        }
    }

    @inlinable
    func compactMapSet<T>(_ transform: (Element) throws -> T?) rethrows -> Set<T> {
        try reduce(into: .init()) { result, element in
            if let value = try transform(element) {
                result.insert(value)
            }
        }
    }
}
