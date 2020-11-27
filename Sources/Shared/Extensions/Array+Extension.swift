import Foundation

public extension Array {
    func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {
        return reduce([:]) { dictionary, element in
            var dictionary = dictionary
            let key = transform(element)
            dictionary[key] = (dictionary[key] ?? []) + [element]
            return dictionary
        }
    }
}
