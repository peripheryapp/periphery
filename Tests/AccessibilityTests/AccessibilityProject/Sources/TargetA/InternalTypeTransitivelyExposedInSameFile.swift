// InternalTypeTransitivelyExposedInSameFile.swift
// Tests for internal types that are transitively exposed within the same file
// but from a different type. These should suggest fileprivate, not private.

class TransitiveExposureClassA {
    // This enum is only directly referenced within ClassA, but it's the return type
    // of getStatus() which IS called from ClassB in the same file.
    // It should be suggested as fileprivate (not private) because ClassB uses it transitively.
    internal enum TransitivelyExposedStatus {
        case active
        case inactive
    }

    func getStatus() -> TransitivelyExposedStatus {
        .active
    }
}

class TransitiveExposureClassB {
    func checkStatus() {
        let a = TransitiveExposureClassA()
        // This call uses TransitivelyExposedStatus transitively through the return type
        let _ = a.getStatus()
    }
}

// Retainer that only uses ClassB (not ClassA.getStatus() directly)
// This ensures getStatus() is only referenced from within this file
public class InternalTypeTransitivelyExposedInSameFileRetainer {
    public init() {}

    public func retain() {
        // Only call checkStatus(), not getStatus() directly
        // So getStatus() is only referenced from checkStatus() in this same file
        TransitiveExposureClassB().checkStatus()
    }
}
