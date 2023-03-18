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
}
