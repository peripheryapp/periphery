import Foundation
import os

public final class UnfairLock: Lock {
    private let lock: Lock

    public init() {
        if #available(macOS 13, *) {
            lock = OSAllocatedUnfairLock()
        } else {
            lock = NSLock()
        }
    }

    @discardableResult
    public func perform<T>(_ operation: () throws -> T) rethrows -> T {
        try lock.perform(operation)
    }
}

private protocol Lock {
    @discardableResult
    func perform<T>(_ operation: () throws -> T) rethrows -> T
}

@available(macOS 13, *)
extension OSAllocatedUnfairLock: Lock where State == Void {
    @discardableResult
    func perform<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        let value = try operation()
        unlock()
        return value
    }
}

extension NSLock: Lock {
    func perform<T>(_ operation: () throws -> T) rethrows -> T {
        try withLock(operation)
    }
}
