import Foundation

public extension Sequence {
    func mapFirst<T>(_ transform: (Element) throws -> T?) rethrows -> T? {
        for item in self {
            if let transformed = try transform(item) {
                return transformed
            }
        }

        return nil
    }

    func flatMapSet<T>(_ transform: (Element) throws -> Set<T>) rethrows -> Set<T> {
        try reduce(into: .init()) { result, element in
            result.formUnion(try transform(element))
        }
    }

    func mapSet<T>(_ transform: (Element) throws -> T) rethrows -> Set<T> {
        try reduce(into: .init()) { result, element in
            result.insert(try transform(element))
        }
    }

    func compactMapSet<T>(_ transform: (Element) throws -> T?) rethrows -> Set<T> {
        try reduce(into: .init()) { result, element in
            if let value = try transform(element) {
                result.insert(value)
            }
        }
    }

    func mapDict<Key, Value>(_ transform: (Element) throws -> (Key, Value)) rethrows -> Dictionary<Key, Value> {
        try reduce(into: .init()) { result, element in
            let pair = try transform(element)
            result[pair.0] = pair.1
        }
    }
}
