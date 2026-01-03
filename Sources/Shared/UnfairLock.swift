import Foundation

#if canImport(os)
    import os
#endif

public final class UnfairLock {
    #if canImport(os)
        private var _osAllocatedUnfairLock: Any?

        private var osAllocatedUnfairLock: OSAllocatedUnfairLock<Void> {
            // swiftlint:disable:next force_cast
            _osAllocatedUnfairLock as! OSAllocatedUnfairLock
        }
    #else
        private var _nsLock: Any?

        private var nsLock: NSLock {
            // swiftlint:disable:next force_cast
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
