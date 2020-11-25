import Foundation

// periphery:ignore
public class Fixture113 {
    func someFunc(param: String) {
        Fixture114().referencedFunc()
    }
}

public class Fixture114 {
    func referencedFunc() {}

    // periphery:ignore:parameters b,c
    public func someFunc(a: String, b: String, c: String) {
        print(a)
    }
}
