import Foundation

public extension Array {
    @inlinable
    func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {
        // swiftlint:disable:next reduce_into
        reduce([:]) { dictionary, element in
            var dictionary = dictionary
            let key = transform(element)
            dictionary[key] = (dictionary[key] ?? []) + [element]
            return dictionary
        }
    }
}
