/*
 MethodCalledFromFreeFunction.swift
 Tests that type members are NOT flagged as private when they are called
 from a free function in the same file.

 A free function has no containing type, so accessing a type's member from
 a free function requires at least fileprivate access, not private.
*/

public class ClassWithMethodCalledFromFreeFunction {
    public init() {}

    func methodCalledFromFreeFunction() -> String { "result" }
    var propertyUsedFromFreeFunction: Int = 0
}

func freeFunctionCallingMethod() {
    let obj = ClassWithMethodCalledFromFreeFunction()
    _ = obj.methodCalledFromFreeFunction()
    _ = obj.propertyUsedFromFreeFunction
}

// Retainer to ensure the free function is used
public class MethodCalledFromFreeFunctionRetainer {
    public init() {}
    public func retain() {
        freeFunctionCallingMethod()
    }
}
