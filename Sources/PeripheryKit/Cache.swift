import Foundation

class Cache<Key: Hashable, T> {
    private var values = [Key: T]()
    private let lock = NSLock()

    private let factory: (Key) throws -> T
    init(_ factory: @escaping (Key) throws -> T) {
        self.factory = factory
    }

    func get(_ input: Key) throws -> T {
        lock.lock(); defer { lock.unlock() }
        return try values[input] ?? factory(input)
    }
}
