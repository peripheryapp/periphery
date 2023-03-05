import Foundation

public final class UnfairLock {
  private let unfairLock: os_unfair_lock_t

  public init() {
    self.unfairLock = .allocate(capacity: 1)
      unfairLock.initialize(to: os_unfair_lock())
  }

  deinit {
      unfairLock.deinitialize(count: 1)
      unfairLock.deallocate()
  }

  @inline(__always)
  public func lock() {
    os_unfair_lock_lock(unfairLock)
  }

  @inline(__always)
  public func unlock() {
    os_unfair_lock_unlock(unfairLock)
  }

  @inline(__always) @discardableResult
  public func withLock<T>(_ operation: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try operation()
  }
}
