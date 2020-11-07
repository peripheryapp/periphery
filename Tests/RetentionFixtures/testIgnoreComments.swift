import Foundation

// periphery:ignore
public class Fixture113 {
    func someFunc(param: String) {}
}

public class Fixture114 {
    // periphery:ignore:parameters b,c
    public func someFunc(a: String, b: String, c: String) {
        print(a)
    }
}
