/*
 RedundantFilePrivateClass.swift
 Tests that a fileprivate class is flagged as redundant when it's only referenced from within its own declaration
*/

fileprivate class RedundantFilePrivateClass {
    fileprivate func someMethod() {
        // Method that does something
    }

    /*
     This internal method creates a self-reference, ensuring the class is "used"
     but only within its own declaration scope, making fileprivate redundant (could be private)
    */
    func createInstance() -> RedundantFilePrivateClass {
        RedundantFilePrivateClass()
    }
}

/*
 This retainer ensures the file is indexed and calls a method on the class.
 The fileprivate class is used, but only within the same file and not by other declarations,
 making the fileprivate access level redundant (could be private).
*/
public class RedundantFilePrivateClassRetainer {
    public init() {}
    public func retain() {
        let instance = RedundantFilePrivateClass()
        _ = instance.createInstance()
    }
}
