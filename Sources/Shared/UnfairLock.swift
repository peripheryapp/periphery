import Foundation

#if canImport(os)
import os
#endif

public final class UnfairLock {
    private var _osAllocatedUnfairLock: Any? = nil
    private var _nsLock: Any? = nil

    #if canImport(os)
    @available(macOS 13, *)
    private var osAllocatedUnfairLock: OSAllocatedUnfairLock<Void> {
        _osAllocatedUnfairLock as! OSAllocatedUnfairLock
    }
    #endif

    private var nsLock: NSLock {
        _nsLock as! NSLock
    }

    public init() {
        #if canImport(os)
        if #available(macOS 13, *) {
            _osAllocatedUnfairLock = OSAllocatedUnfairLock()
        } else {
            _nsLock = NSLock()
        }
        #else
        _nsLock = NSLock()
        #endif

    }

    @discardableResult
    @inline(__always)
    public func perform<T>(_ operation: () throws -> T) rethrows -> T {
        #if canImport(os)
        if #available(macOS 13, *) {
            osAllocatedUnfairLock.lock()
            let value = try operation()
            osAllocatedUnfairLock.unlock()
            return value
        } else {
            nsLock.lock()
            let value = try operation()
            nsLock.unlock()
            return value
        }
        #else
        nsLock.lock()
        let value = try operation()
        nsLock.unlock()
        return value
        #endif
    }
}
