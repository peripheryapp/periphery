import Foundation

#if canImport(os)
import os
#endif

public final class UnfairLock {
    #if canImport(os)
    private var _osAllocatedUnfairLock: Any? = nil

    private var osAllocatedUnfairLock: OSAllocatedUnfairLock<Void> {
        _osAllocatedUnfairLock as! OSAllocatedUnfairLock
    }
    #else
    private var _nsLock: Any? = nil

    private var nsLock: NSLock {
        _nsLock as! NSLock
    }
    #endif

    public init() {
        #if canImport(os)
        _osAllocatedUnfairLock = OSAllocatedUnfairLock()
        #else
        _nsLock = NSLock()
        #endif
    }

    @discardableResult
    @inline(__always)
    public func perform<T>(_ operation: () throws -> T) rethrows -> T {
        #if canImport(os)
        osAllocatedUnfairLock.lock()
        let value = try operation()
        osAllocatedUnfairLock.unlock()
        return value
        #else
        nsLock.lock()
        let value = try operation()
        nsLock.unlock()
        return value
        #endif
    }
}
