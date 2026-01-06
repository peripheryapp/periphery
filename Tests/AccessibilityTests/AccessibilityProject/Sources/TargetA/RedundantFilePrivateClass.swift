/// This file tests a case where fileprivate is actually NOT redundant because the
/// class is accessed from a different type (RedundantFilePrivateClassRetainer).

fileprivate class RedundantFilePrivateClass {
    fileprivate func someMethod() {
        // Method that does something
    }

    /// This internal method creates a self-reference, ensuring the class is "used"
    /// but only within its own declaration scope, making fileprivate redundant (could be private)
    func createInstance() -> RedundantFilePrivateClass {
        RedundantFilePrivateClass()
    }
}

/// This retainer accesses RedundantFilePrivateClass from a different type,
/// which means fileprivate is necessary (NOT redundant).
public class RedundantFilePrivateClassRetainer {
    public init() {}
    public func retain() {
        let instance = RedundantFilePrivateClass()
        _ = instance.createInstance()
    }
}
