import Foundation

#if canImport(os)
import os
#endif

public final class UnfairLock: Lock {
    private let lock: Lock

    public init() {
        #if canImport(os)
        if #available(macOS 13, *) {
            lock = OSAllocatedUnfairLock()
        } else {
            lock = NSLock()
        }
        #else
        lock = NSLock()
        #endif
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

#if canImport(os)
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
#endif

extension NSLock: Lock {
    func perform<T>(_ operation: () throws -> T) rethrows -> T {
        lock()
        let value = try operation()
        unlock()
        return value
    }
}
