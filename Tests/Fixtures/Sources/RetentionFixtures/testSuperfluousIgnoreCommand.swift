import Foundation

// MARK: - Superfluous ignore command (function is actually used)

// periphery:ignore
public func superfluouslyIgnoredFunc() {
    print("I am actually used!")
}

// This function calls the ignored one, making the ignore superfluous
public func callerOfSuperfluouslyIgnoredFunc() {
    superfluouslyIgnoredFunc()
}

// MARK: - Superfluous ignore command on class (class is used)

// periphery:ignore
public class SuperfluouslyIgnoredClass {
    public func someMethod() {}
}

public func useSuperfluouslyIgnoredClass() {
    _ = SuperfluouslyIgnoredClass()
}

// MARK: - Non-superfluous ignore command (function is NOT used)

// periphery:ignore
public func correctlyIgnoredFunc() {
    print("I am NOT used anywhere!")
}

// MARK: - Non-superfluous ignore command (class is NOT used)

// periphery:ignore
public class CorrectlyIgnoredClass {
    public func someMethod() {}
}

// MARK: - Ignored declaration within non-ignored parent

public class NonIgnoredParentClass {
    // This method is ignored but actually used - superfluous
    // periphery:ignore
    public func superfluouslyIgnoredMethod() {
        print("I am used!")
    }

    // This method is ignored and NOT used - correctly ignored
    // periphery:ignore
    public func correctlyIgnoredMethod() {
        print("I am not used!")
    }

    public func callerMethod() {
        superfluouslyIgnoredMethod()
    }
}

// MARK: - Deeply nested declarations within ignored hierarchy

// When an entire class is ignored, internal references between its members
// should NOT make those members appear superfluously ignored.
// periphery:ignore
public class DeeplyNestedIgnoredClass {
    public func methodA() {
        methodB()  // Internal reference - should NOT make methodB superfluous
    }

    public func methodB() {
        methodC()  // Internal reference - should NOT make methodC superfluous
    }

    public func methodC() {
        print("Deeply nested")
    }
}

// MARK: - Superfluous ignore for parameters

public class ParameterIgnoreClass {
    // This parameter is ignored but actually used - superfluous
    // periphery:ignore:parameters usedParam
    public func superfluousParamIgnore(usedParam: String) {
        print(usedParam)  // Parameter IS used, so ignore is superfluous
    }

    // This parameter is ignored and NOT used - correctly ignored
    // periphery:ignore:parameters unusedParam
    public func correctParamIgnore(unusedParam: String) {
        print("Not using the param")
    }
}

